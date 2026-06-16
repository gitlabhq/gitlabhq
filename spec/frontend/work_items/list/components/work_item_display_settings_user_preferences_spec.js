import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdownItem, GlToggle } from '@gitlab/ui';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import WorkItemDisplaySettingsUserPreferences from '~/work_items/list/components/work_item_display_settings_user_preferences.vue';
import updateWorkItemsDisplaySettings from '~/work_items/graphql/update_user_preferences.mutation.graphql';

Vue.use(VueApollo);

jest.mock('~/alert');

const DEFAULT_PROPS = {
  fullPath: 'gitlab-org/gitlab',
  workItemTypeId: 'gid://gitlab/WorkItems::Type/8',
};

describe('WorkItemDisplaySettingsUserPreferences', () => {
  let wrapper;
  let mockApolloProvider;
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const updateDisplaySettingsHandler = jest.fn().mockResolvedValue({
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

  const findSidePanelToggleItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findSidePanelToggle = () => wrapper.findComponent(GlToggle);

  const createComponent = ({
    props = {},
    mutationHandler = updateDisplaySettingsHandler,
    mountFn = shallowMountExtended,
  } = {}) => {
    mockApolloProvider = createMockApollo([[updateWorkItemsDisplaySettings, mutationHandler]]);

    wrapper = mountFn(WorkItemDisplaySettingsUserPreferences, {
      apolloProvider: mockApolloProvider,
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders the side panel toggle with the value from commonPreferences', () => {
    createComponent({
      props: { commonPreferences: { shouldOpenItemsInSidePanel: false } },
      mountFn: mountExtended,
    });

    expect(findSidePanelToggle().props('value')).toBe(false);
  });

  it('defaults the side panel toggle to true when commonPreferences is empty', () => {
    createComponent({ mountFn: mountExtended });

    expect(findSidePanelToggle().props('value')).toBe(true);
  });

  it('calls the mutation with the toggled value when the side panel item emits action', async () => {
    createComponent({
      props: { commonPreferences: { shouldOpenItemsInSidePanel: true } },
    });

    findSidePanelToggleItem().vm.$emit('action');
    await waitForPromises();

    expect(updateDisplaySettingsHandler).toHaveBeenCalledWith({
      input: {
        workItemsDisplaySettings: { shouldOpenItemsInSidePanel: false },
      },
    });
  });

  it('shows loading state while saving', async () => {
    createComponent({
      props: { commonPreferences: { shouldOpenItemsInSidePanel: true } },
      mountFn: mountExtended,
    });

    expect(findSidePanelToggle().props('isLoading')).toBe(false);

    findSidePanelToggleItem().vm.$emit('action');
    await nextTick();

    expect(findSidePanelToggle().props('isLoading')).toBe(true);

    await waitForPromises();

    expect(findSidePanelToggle().props('isLoading')).toBe(false);
  });

  it('shows an alert when the mutation fails', async () => {
    const error = new Error('Network error');
    const errorHandler = jest.fn().mockRejectedValue(error);

    createComponent({
      props: { commonPreferences: { shouldOpenItemsInSidePanel: true } },
      mutationHandler: errorHandler,
    });

    findSidePanelToggleItem().vm.$emit('action');
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'Something went wrong while saving the preference.',
      captureError: true,
      error,
    });
  });

  it('tracks work_item_drawer_disabled when the user disables the side panel', async () => {
    createComponent({
      props: { commonPreferences: { shouldOpenItemsInSidePanel: true } },
    });

    const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

    findSidePanelToggleItem().vm.$emit('action');
    await waitForPromises();

    expect(trackEventSpy).toHaveBeenCalledWith('work_item_drawer_disabled', {}, undefined);
  });

  it('does not track work_item_drawer_disabled when the user enables the side panel', async () => {
    createComponent({
      props: { commonPreferences: { shouldOpenItemsInSidePanel: false } },
    });

    const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

    findSidePanelToggleItem().vm.$emit('action');
    await waitForPromises();

    expect(trackEventSpy).not.toHaveBeenCalledWith(
      'work_item_drawer_disabled',
      expect.anything(),
      undefined,
    );
  });
});
