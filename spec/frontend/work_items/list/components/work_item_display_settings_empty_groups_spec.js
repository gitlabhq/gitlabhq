import { GlDisclosureDropdownItem, GlToggle } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import WorkItemDisplaySettingsEmptyGroups from '~/work_items/list/components/work_item_display_settings_empty_groups.vue';
import {
  persistMetadataPreference,
  alertPreferenceError,
} from '~/work_items/list/display_settings_preferences';

jest.mock('~/work_items/list/display_settings_preferences', () => ({
  persistMetadataPreference: jest.fn(),
  alertPreferenceError: jest.fn(),
}));

const DEFAULT_PROPS = {
  fullPath: 'gitlab-org/gitlab',
  workItemTypeId: 'gid://gitlab/WorkItems::Type/8',
  sortKey: 'CREATED_DESC',
};

describe('WorkItemDisplaySettingsEmptyGroups', () => {
  let wrapper;

  const findToggleItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findToggle = () => wrapper.findComponent(GlToggle);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemDisplaySettingsEmptyGroups, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('defaults the toggle to true when namespacePreferences is empty', () => {
    createComponent();

    expect(findToggle().props('value')).toBe(true);
  });

  it('renders the toggle with the value from namespacePreferences', () => {
    createComponent({ props: { namespacePreferences: { showEmptyGroups: false } } });

    expect(findToggle().props('value')).toBe(false);
  });

  it('persists the toggled value as a user preference, preserving other settings', async () => {
    createComponent({
      props: { namespacePreferences: { showEmptyGroups: true, hiddenMetadataKeys: ['labels'] } },
    });

    findToggleItem().vm.$emit('action');
    await waitForPromises();

    // No apolloProvider is stubbed in this shallow mount, so $apollo is undefined here.
    expect(persistMetadataPreference).toHaveBeenCalledWith({
      apolloClient: undefined,
      namespace: 'gitlab-org/gitlab',
      workItemTypeId: 'gid://gitlab/WorkItems::Type/8',
      userPreferencesOnly: false,
      displaySettings: { showEmptyGroups: false, hiddenMetadataKeys: ['labels'] },
      sort: 'CREATED_DESC',
    });
  });

  it('shows a loading state while persisting', async () => {
    let resolvePersist;
    persistMetadataPreference.mockImplementation(
      () =>
        new Promise((resolve) => {
          resolvePersist = resolve;
        }),
    );
    createComponent();

    expect(findToggle().props('isLoading')).toBe(false);

    findToggleItem().vm.$emit('action');
    await nextTick();

    expect(findToggle().props('isLoading')).toBe(true);

    resolvePersist();
    await waitForPromises();

    expect(findToggle().props('isLoading')).toBe(false);
  });

  it('shows an alert when persisting fails', async () => {
    const error = new Error('Network error');
    persistMetadataPreference.mockRejectedValueOnce(error);
    createComponent();

    findToggleItem().vm.$emit('action');
    await waitForPromises();

    expect(alertPreferenceError).toHaveBeenCalledWith(error);
  });

  describe('when the view is a saved view', () => {
    it('emits update-settings instead of persisting', async () => {
      createComponent({ props: { isSavedView: true } });

      findToggleItem().vm.$emit('action');
      await waitForPromises();

      expect(wrapper.emitted('update-settings')).toEqual([[{ showEmptyGroups: false }]]);
      expect(persistMetadataPreference).not.toHaveBeenCalled();
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('tracks hiding empty groups', async () => {
      createComponent();
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findToggleItem().vm.$emit('action');
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'configure_columns_on_work_item_board',
        { label: 'hide_empty_groups' },
        undefined,
      );
    });

    it('tracks showing empty groups', async () => {
      createComponent({ props: { namespacePreferences: { showEmptyGroups: false } } });
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findToggleItem().vm.$emit('action');
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'configure_columns_on_work_item_board',
        { label: 'show_empty_groups' },
        undefined,
      );
    });
  });
});
