import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdown, GlToggle, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemUserPreferences from '~/work_items/list/components/work_item_user_preferences.vue';
import updateWorkItemsDisplaySettings from '~/work_items/graphql/update_user_preferences.mutation.graphql';
import updateWorkItemListUserPreference from '~/work_items/graphql/update_work_item_list_user_preferences.mutation.graphql';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS, METADATA_KEYS } from '~/work_items/constants';
import { isLoggedIn } from '~/lib/utils/common_utils';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/common_utils');

// Mock data
const mockDisplaySettings = {
  commonPreferences: { shouldOpenItemsInSidePanel: true },
  namespacePreferences: { hiddenMetadataKeys: [] },
};

const firstMetadataKey = METADATA_KEYS[Object.keys(METADATA_KEYS)[0]];

describe('WorkItemUserPreferences', () => {
  let wrapper;
  let mockApolloProvider;
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  // Mock handlers
  const successHandler = jest.fn().mockResolvedValue({
    data: {
      userPreferencesUpdate: {
        __typename: 'UserPreferencesUpdatePayload',
        userPreferences: {
          __typename: 'UserPreferences',
          workItemsDisplaySettings: { shouldOpenItemsInSidePanel: false },
        },
        errors: [],
      },
    },
  });

  const namespacePreferencesHandler = jest.fn().mockResolvedValue({
    data: {
      workItemUserPreferenceUpdate: {
        __typename: 'WorkItemUserPreferenceUpdatePayload',
        errors: [],
        userPreferences: {
          __typename: 'UserPreferences',
          displaySettings: { hiddenMetadataKeys: [firstMetadataKey] },
          sort: 'UPDATED_DESC',
        },
      },
    },
  });

  const createComponent = ({
    mountFn = shallowMount,
    props = {},
    provide = {},
    mutationHandler = successHandler,
    namespaceHandler = namespacePreferencesHandler,
    isLoggedInValue = true,
  } = {}) => {
    mockApolloProvider = createMockApollo([
      [updateWorkItemsDisplaySettings, mutationHandler],
      [updateWorkItemListUserPreference, namespaceHandler],
    ]);

    isLoggedIn.mockReturnValue(isLoggedInValue);

    wrapper = mountFn(WorkItemUserPreferences, {
      apolloProvider: mockApolloProvider,
      propsData: {
        displaySettings: mockDisplaySettings,
        fullPath: 'gitlab-org/gitlab',
        isEpicsList: false,
        isGroup: false,
        workItemTypeId: 'gid://gitlab/WorkItems::Type/8',
        sortKey: 'UPDATED_DESC',
        preventAutoSubmit: false,
        ...props,
      },
      provide: {
        isGroupIssuesList: false,
        ...provide,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findToggles = () => wrapper.findAllComponents(GlToggle);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('when user is signed in', () => {
    describe('rendering', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders dropdown with correct props', () => {
        expect(findDropdown().exists()).toBe(true);
        expect(findDropdown().props('toggleText')).toBe('Display options');
      });

      it('renders toggles for all applicable metadata fields', () => {
        const toggles = findToggles();
        // All metadata fields + side panel toggle
        expect(toggles).toHaveLength(WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.length + 1);
      });

      it('handles empty displaySettings gracefully', () => {
        createComponent({
          props: {
            displaySettings: {
              commonPreferences: {},
              namespacePreferences: {},
            },
          },
        });

        const sidePanelToggle = findToggles().at(findToggles().length - 1);
        expect(sidePanelToggle.props('value')).toBe(true); // defaults to true
      });
    });

    describe('side panel preference toggle', () => {
      beforeEach(() => {
        createComponent();
      });

      it('updates cache and calls mutation on toggle', async () => {
        const dropdownItems = findDropdownItems();
        const sidePanelItem = dropdownItems.at(dropdownItems.length - 1);

        sidePanelItem.vm.$emit('action');
        await waitForPromises();

        expect(successHandler).toHaveBeenCalledWith({
          input: {
            workItemsDisplaySettings: { shouldOpenItemsInSidePanel: false },
          },
        });
      });

      it('shows loading state while saving', async () => {
        const dropdownItems = findDropdownItems();
        const sidePanelItem = dropdownItems.at(dropdownItems.length - 1);
        const sidePanelToggle = findToggles().at(findToggles().length - 1);

        expect(sidePanelToggle.props('isLoading')).toBe(false);

        sidePanelItem.vm.$emit('action');
        await nextTick();

        expect(sidePanelToggle.props('isLoading')).toBe(true);

        await waitForPromises();

        expect(sidePanelToggle.props('isLoading')).toBe(false);
      });

      it('handles mutation errors gracefully', async () => {
        const error = new Error('Network error');
        const errorHandler = jest.fn().mockRejectedValue(error);

        createComponent({ mutationHandler: errorHandler });

        const dropdownItems = findDropdownItems();
        const sidePanelItem = dropdownItems.at(dropdownItems.length - 1);

        sidePanelItem.vm.$emit('action');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong while saving the preference.',
          captureError: true,
          error,
        });
      });

      it('tracks work_item_drawer_disabled event when user disables drawer', async () => {
        const dropdownItems = findDropdownItems();
        const sidePanelItem = dropdownItems.at(dropdownItems.length - 1);

        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
        sidePanelItem.vm.$emit('action');
        await waitForPromises();
        expect(trackEventSpy).toHaveBeenCalledWith('work_item_drawer_disabled', {}, undefined);
      });
    });

    describe('metadata preferences', () => {
      it('renders toggles for group-applicable metadata fields in group context', () => {
        createComponent({ props: { isGroup: true } });
        const toggles = findToggles();
        const groupApplicableFields = WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.filter(
          (field) => field.isPresentInGroup,
        );
        expect(toggles).toHaveLength(groupApplicableFields.length + 1);
      });

      it('renders only group-applicable metadata fields in group context', () => {
        createComponent({ mountFn: mount, props: { isGroup: true } });

        const expectedGroupFields = WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.filter(
          (field) => field.isPresentInGroup,
        );

        const allToggles = findToggles();
        const metadataToggles = allToggles;

        expect(metadataToggles).toHaveLength(expectedGroupFields.length + 1);
      });

      it('does not render `Status` settings for epics listing', () => {
        createComponent({
          mountFn: mount,
          props: { isEpicsList: true, isGroup: true },
        });

        const firstMetadataItem = findDropdownItems().at(0);

        expect(firstMetadataItem.text()).not.toBe('Status');
      });

      it('does not render `Status` settings for service desk list', () => {
        createComponent({ mountFn: mount, props: { isServiceDeskList: true } });

        const firstMetadataItem = findDropdownItems().at(0);

        expect(firstMetadataItem.text()).not.toBe('Status');
      });

      it('renders `Status` settings for group work item listing', () => {
        createComponent({ mountFn: mount, props: { isGroup: true } });

        const firstMetadataItem = findDropdownItems().at(0);

        expect(firstMetadataItem.text()).toBe('Status');
      });

      it('renders `Status` settings for project work item listing', () => {
        createComponent({ mountFn: mount });

        const firstMetadataItem = findDropdownItems().at(0);

        expect(firstMetadataItem.text()).toBe('Status');
      });
    });

    describe('when preventAutoSubmit is false', () => {
      beforeEach(() => {
        createComponent({ props: { preventAutoSubmit: false } });
      });

      describe('metadata field toggles', () => {
        it('toggles metadata field visibility and updates cache', async () => {
          const dropdownItems = findDropdownItems();
          const firstMetadataItem = dropdownItems.at(0);

          firstMetadataItem.vm.$emit('action');
          await waitForPromises();

          expect(namespacePreferencesHandler).toHaveBeenCalledWith({
            namespace: 'gitlab-org/gitlab',
            displaySettings: {
              hiddenMetadataKeys: [firstMetadataKey],
            },
          });
        });

        it('handles namespace preference errors gracefully', async () => {
          const error = new Error('Network error');
          const errorHandler = jest.fn().mockRejectedValue(error);

          createComponent({ namespaceHandler: errorHandler });

          const dropdownItems = findDropdownItems();
          const firstMetadataItem = dropdownItems.at(0);

          firstMetadataItem.vm.$emit('action');
          await waitForPromises();

          expect(createAlert).toHaveBeenCalledWith({
            message: 'Something went wrong while saving the preference.',
            captureError: true,
            error,
          });
        });

        it('tracks work_item_metadata_field_hidden event when user hides field', async () => {
          const dropdownItems = findDropdownItems();
          const firstMetadataItem = dropdownItems.at(0);

          firstMetadataItem.vm.$emit('action');
          await waitForPromises();

          const { trackEventSpy } = bindInternalEventDocument(document.body);
          expect(trackEventSpy).toHaveBeenCalledWith(
            'work_item_metadata_field_hidden',
            {
              property: firstMetadataKey,
            },
            undefined,
          );
        });
      });
    });

    describe('when preventAutoSubmit is true', () => {
      beforeEach(() => {
        createComponent({ props: { preventAutoSubmit: true } });
      });

      describe('metadata field toggles', () => {
        it('toggles metadata field visibility and emits local change', async () => {
          const dropdownItems = findDropdownItems();
          const firstMetadataItem = dropdownItems.at(0);

          firstMetadataItem.vm.$emit('action');
          await waitForPromises();

          expect(namespacePreferencesHandler).not.toHaveBeenCalled();

          expect(wrapper.emitted('local-update')).toEqual([
            [
              {
                hiddenMetadataKeys: [firstMetadataKey],
              },
            ],
          ]);
        });

        it('tracks work_item_metadata_field_hidden event when user hides field', async () => {
          const dropdownItems = findDropdownItems();
          const firstMetadataItem = dropdownItems.at(0);

          firstMetadataItem.vm.$emit('action');
          await waitForPromises();

          const { trackEventSpy } = bindInternalEventDocument(document.body);
          expect(trackEventSpy).toHaveBeenCalledWith(
            'work_item_metadata_field_hidden',
            {
              property: firstMetadataKey,
            },
            undefined,
          );
        });
      });
    });
  });

  describe('when user is not signed in', () => {
    it('does not render dropdown', () => {
      createComponent({ isLoggedInValue: false });
      expect(findDropdown().exists()).toBe(false);
    });
  });
});
