import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdownItem, GlSearchBoxByType, GlToggle } from '@gitlab/ui';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemDisplaySettingsMetadata from '~/work_items/list/components/work_item_display_settings_metadata.vue';
import updateWorkItemListUserPreference from '~/work_items/graphql/update_work_item_list_user_preferences.mutation.graphql';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS,
  WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS_SORTED,
  ROUTES,
} from '~/work_items/constants';

Vue.use(VueApollo);

jest.mock('~/alert');

const firstAlphabeticalKey = WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS_SORTED[0].key;

describe('WorkItemDisplaySettingsMetadata', () => {
  let wrapper;
  let mockApolloProvider;
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const namespacePreferencesHandler = jest.fn().mockResolvedValue({
    data: {
      workItemUserPreferenceUpdate: {
        __typename: 'WorkItemUserPreferenceUpdatePayload',
        errors: [],
        userPreferences: {
          __typename: 'UserPreferences',
          displaySettings: { hiddenMetadataKeys: [firstAlphabeticalKey] },
          sort: 'UPDATED_DESC',
        },
      },
    },
  });

  const createComponent = ({
    mountFn = shallowMountExtended,
    props = {},
    namespaceHandler = namespacePreferencesHandler,
    routeName = ROUTES.index,
  } = {}) => {
    mockApolloProvider = createMockApollo([[updateWorkItemListUserPreference, namespaceHandler]]);

    wrapper = mountFn(WorkItemDisplaySettingsMetadata, {
      apolloProvider: mockApolloProvider,
      mocks: {
        $route: { name: routeName },
      },
      propsData: {
        namespacePreferences: { hiddenMetadataKeys: [] },
        fullPath: 'gitlab-org/gitlab',
        isGroup: false,
        isServiceDeskList: false,
        workItemTypeId: 'gid://gitlab/WorkItems::Type/8',
        sortKey: 'UPDATED_DESC',
        ...props,
      },
    });
  };

  const findShownSection = () => wrapper.findByTestId('shown-preferences');
  const findHiddenSection = () => wrapper.findByTestId('hidden-preferences');
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findToggles = () => wrapper.findAllComponents(GlToggle);
  const findFirstDropdownItem = () => findDropdownItems().at(0);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findNoFieldsFound = () => wrapper.findByTestId('no-fields-found');

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders a toggle for every setting field', () => {
    createComponent();

    expect(findToggles()).toHaveLength(WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.length);
  });

  it('renders only group-applicable metadata fields in group context', () => {
    createComponent({ props: { isGroup: true } });

    const groupApplicableFields = WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.filter(
      (field) => field.isPresentInGroup,
    );
    expect(findToggles()).toHaveLength(groupApplicableFields.length);
  });

  describe('shown/hidden grouping', () => {
    it('renders only the shown section when no fields are hidden', () => {
      createComponent({ mountFn: mountExtended });

      expect(findShownSection().exists()).toBe(true);
      expect(findHiddenSection().exists()).toBe(false);
    });

    it('renders both sections when at least one field is hidden', () => {
      createComponent({
        mountFn: mountExtended,
        props: { namespacePreferences: { hiddenMetadataKeys: [firstAlphabeticalKey] } },
      });

      expect(findShownSection().exists()).toBe(true);
      expect(findHiddenSection().exists()).toBe(true);
    });

    it('renders only the hidden section when every field is hidden', () => {
      createComponent({
        mountFn: mountExtended,
        props: {
          namespacePreferences: {
            hiddenMetadataKeys: WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.map((f) => f.key),
          },
        },
      });

      expect(findShownSection().exists()).toBe(false);
      expect(findHiddenSection().exists()).toBe(true);
    });

    it('sorts toggles alphabetically by label across both sections', () => {
      const hidden = WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS_SORTED.slice(0, 2).map(
        (f) => f.key,
      );
      createComponent({
        mountFn: mountExtended,
        props: { namespacePreferences: { hiddenMetadataKeys: hidden } },
      });

      const labelsInOrder = findToggles().wrappers.map((t) => t.props('label'));
      const expectedHiddenLabels = WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS_SORTED.filter((f) =>
        hidden.includes(f.key),
      ).map((f) => f.label);
      const expectedShownLabels = WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS_SORTED.filter(
        (f) => !hidden.includes(f.key),
      ).map((f) => f.label);

      expect(labelsInOrder).toEqual([...expectedShownLabels, ...expectedHiddenLabels]);
    });
  });

  describe('fields search', () => {
    it('correctly filters toggles', async () => {
      createComponent({ mountFn: mountExtended });

      await findSearchBox().vm.$emit('input', 'lab');

      const labels = findToggles().wrappers.map((t) => t.props('label'));
      expect(labels).toEqual(['Labels']);
    });

    it('restores the full list when the search is cleared', async () => {
      createComponent({ mountFn: mountExtended });
      const totalFields = findToggles().length;

      await findSearchBox().vm.$emit('input', 'lab');
      expect(findToggles()).toHaveLength(1);

      await findSearchBox().vm.$emit('input', '');
      expect(findToggles()).toHaveLength(totalFields);
    });

    it('shows the no fields found state when no matches exist', async () => {
      createComponent({ mountFn: mountExtended });

      await findSearchBox().vm.$emit('input', 'no-match');

      expect(findNoFieldsFound().exists()).toBe(true);
      expect(findShownSection().exists()).toBe(false);
      expect(findHiddenSection().exists()).toBe(false);
    });
  });

  describe('when not on a saved view', () => {
    beforeEach(() => {
      createComponent({ routeName: ROUTES.index });
    });

    it('toggles metadata field visibility via the mutation', async () => {
      findFirstDropdownItem().vm.$emit('action');
      await waitForPromises();

      expect(namespacePreferencesHandler).toHaveBeenCalledWith({
        namespace: 'gitlab-org/gitlab',
        displaySettings: {
          hiddenMetadataKeys: [firstAlphabeticalKey],
        },
      });
    });

    it('shows an alert when the mutation fails', async () => {
      const error = new Error('Network error');
      const errorHandler = jest.fn().mockRejectedValue(error);
      createComponent({ namespaceHandler: errorHandler });

      findFirstDropdownItem().vm.$emit('action');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while saving the preference.',
        captureError: true,
        error,
      });
    });

    it('tracks work_item_metadata_field_hidden when a field is hidden', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findFirstDropdownItem().vm.$emit('action');
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'work_item_metadata_field_hidden',
        { property: firstAlphabeticalKey },
        undefined,
      );
    });
  });

  describe('when on a saved view', () => {
    beforeEach(() => {
      createComponent({ routeName: ROUTES.savedView });
    });

    it('updates settings without calling the mutation', async () => {
      findFirstDropdownItem().vm.$emit('action');
      await waitForPromises();

      expect(namespacePreferencesHandler).not.toHaveBeenCalled();
      expect(wrapper.emitted('update-settings')).toEqual([
        [{ hiddenMetadataKeys: [firstAlphabeticalKey] }],
      ]);
    });

    it('tracks work_item_metadata_field_hidden when a field is hidden', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findFirstDropdownItem().vm.$emit('action');
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'work_item_metadata_field_hidden',
        { property: firstAlphabeticalKey },
        undefined,
      );
    });
  });
});
