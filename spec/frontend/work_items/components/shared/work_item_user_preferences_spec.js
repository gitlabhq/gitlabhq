import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdown, GlToggle, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemUserPreferences from '~/work_items/components/shared/work_item_user_preferences.vue';
import updateWorkItemsDisplaySettings from '~/work_items/graphql/update_user_preferences.mutation.graphql';
import updateWorkItemListUserPreference from '~/work_items/graphql/update_work_item_list_user_preferences.mutation.graphql';
import getUserWorkItemsDisplaySettingsPreferences from '~/work_items/graphql/get_user_preferences.query.graphql';
import { WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS } from '~/work_items/constants';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

Vue.use(VueApollo);

jest.mock('~/alert');

// Mock data
const mockDisplaySettings = {
  commonPreferences: { shouldOpenItemsInSidePanel: true },
  namespacePreferences: { hiddenMetadataKeys: [] },
};

const mockCacheData = {
  currentUser: {
    __typename: 'User',
    id: 'gid://gitlab/User/1',
    userPreferences: {
      __typename: 'UserPreferences',
      workItemsDisplaySettings: { shouldOpenItemsInSidePanel: true },
    },
    workItemPreferences: null,
  },
};

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
          displaySettings: { hiddenMetadataKeys: ['assignee'] },
        },
      },
    },
  });

  const createComponent = ({
    props = {},
    provide = {},
    mutationHandler = successHandler,
    namespaceHandler = namespacePreferencesHandler,
  } = {}) => {
    mockApolloProvider = createMockApollo([
      [updateWorkItemsDisplaySettings, mutationHandler],
      [updateWorkItemListUserPreference, namespaceHandler],
    ]);

    // Set up cache with initial data
    mockApolloProvider.clients.defaultClient.cache.writeQuery({
      query: getUserWorkItemsDisplaySettingsPreferences,
      variables: { namespace: 'gitlab-org/gitlab' },
      data: mockCacheData,
    });

    wrapper = shallowMount(WorkItemUserPreferences, {
      apolloProvider: mockApolloProvider,
      propsData: {
        displaySettings: mockDisplaySettings,
        fullPath: 'gitlab-org/gitlab',
        ...props,
      },
      provide: {
        isSignedIn: true,
        isGroup: false,
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

    describe('side panel preference toggle', () => {
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

        // Verify cache was updated
        const updatedCacheData = mockApolloProvider.clients.defaultClient.cache.readQuery({
          query: getUserWorkItemsDisplaySettingsPreferences,
          variables: { namespace: 'gitlab-org/gitlab' },
        });

        expect(updatedCacheData.currentUser.userPreferences.workItemsDisplaySettings).toEqual({
          shouldOpenItemsInSidePanel: false,
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

    describe('metadata field toggles', () => {
      it('renders toggles for group-applicable metadata fields in group context', () => {
        createComponent({ provide: { isGroup: true } });
        const toggles = findToggles();
        const groupApplicableFields = WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.filter(
          (field) => field.isPresentInGroup,
        );
        expect(toggles).toHaveLength(groupApplicableFields.length + 1);
      });

      it('toggles metadata field visibility and updates cache', async () => {
        const dropdownItems = findDropdownItems();
        const firstMetadataItem = dropdownItems.at(0);

        firstMetadataItem.vm.$emit('action');
        await waitForPromises();

        expect(namespacePreferencesHandler).toHaveBeenCalledWith({
          namespace: 'gitlab-org/gitlab',
          displaySettings: {
            hiddenMetadataKeys: ['assignee'],
          },
        });

        const updatedCacheData = mockApolloProvider.clients.defaultClient.cache.readQuery({
          query: getUserWorkItemsDisplaySettingsPreferences,
          variables: { namespace: 'gitlab-org/gitlab' },
        });

        expect(updatedCacheData.currentUser.workItemPreferences.displaySettings).toEqual({
          hiddenMetadataKeys: ['assignee'],
        });
      });

      it('prevents multiple clicks from triggering duplicate API calls while loading', async () => {
        const dropdownItems = findDropdownItems();
        const firstMetadataItem = dropdownItems.at(0);
        const secondMetadataItem = dropdownItems.at(1);

        firstMetadataItem.vm.$emit('action');
        secondMetadataItem.vm.$emit('action'); // Should be ignored while loading

        await waitForPromises();

        // Verify only one API call was made
        expect(namespacePreferencesHandler).toHaveBeenCalledTimes(1);

        // Verify cache was updated correctly (only once)
        const updatedCacheData = mockApolloProvider.clients.defaultClient.cache.readQuery({
          query: getUserWorkItemsDisplaySettingsPreferences,
          variables: { namespace: 'gitlab-org/gitlab' },
        });

        expect(updatedCacheData.currentUser.workItemPreferences.displaySettings).toEqual({
          hiddenMetadataKeys: ['assignee'],
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

      it('renders only group-applicable metadata fields in group context', () => {
        createComponent({ provide: { isGroup: true } });

        const expectedGroupFields = WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.filter(
          (field) => field.isPresentInGroup,
        );

        const allToggles = findToggles();
        const metadataToggles = allToggles;

        expect(metadataToggles).toHaveLength(expectedGroupFields.length + 1);
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
            property: 'assignee',
          },
          undefined,
        );
      });
    });
  });

  describe('when user is not signed in', () => {
    it('does not render dropdown', () => {
      createComponent({ provide: { isSignedIn: false } });
      expect(findDropdown().exists()).toBe(false);
    });
  });
});
