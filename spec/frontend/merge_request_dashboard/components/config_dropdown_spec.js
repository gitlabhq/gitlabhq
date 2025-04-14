import Vue, { nextTick } from 'vue';
import { GlToggle, GlCollapsibleListbox } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import ConfigDropdown from '~/merge_request_dashboard/components/config_dropdown.vue';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import updatePreferencesMutation from '~/merge_request_dashboard/queries/update_preferences.mutation.graphql';

Vue.use(VueApollo);

describe('Merge request dashboard config dropdown component', () => {
  let wrapper;
  let setIsShowingLabelsMutationMock;
  let updatePreferencesMutationMock;

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  function createComponent(isShowingLabels = false) {
    setIsShowingLabelsMutationMock = jest.fn();
    updatePreferencesMutationMock = jest.fn().mockResolvedValue({
      data: {
        userPreferencesUpdate: { userPreferences: { mergeRequestDashboardListType: 'ROLE_BASED' } },
      },
    });
    const resolvers = {
      Mutation: {
        setIsShowingLabels: setIsShowingLabelsMutationMock,
      },
    };

    const apolloProvider = createMockApollo(
      [[updatePreferencesMutation, updatePreferencesMutationMock]],
      resolvers,
    );

    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: isShowingLabelsQuery,
      data: {
        isShowingLabels,
      },
    });

    wrapper = shallowMountExtended(ConfigDropdown, {
      apolloProvider,
    });
  }

  it('sends tracking event when dropdown is shown', async () => {
    createComponent();

    const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

    findDropdown().vm.$emit('shown');

    await waitForPromises();

    expect(trackEventSpy).toHaveBeenCalledWith(
      'open_display_preferences_dropdown_on_merge_request_homepage',
      {},
      undefined,
    );
  });

  it('mutates apollo cache on LocalStorageSync input event', async () => {
    createComponent();

    wrapper.findComponent(LocalStorageSync).vm.$emit('input', true);

    await nextTick();

    expect(setIsShowingLabelsMutationMock).toHaveBeenCalledWith(
      {},
      {
        isShowingLabels: true,
      },
      expect.anything(),
      expect.anything(),
    );
  });

  it.each`
    isShowingLabels | property
    ${false}        | ${'on'}
    ${true}         | ${'off'}
  `(
    'should call trackEvent method with property as `$property` when GlDisclosureDropdownItem action event is triggered with isShowingLabels value as `$isShowingLabels`',
    async ({ isShowingLabels, property }) => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      createComponent(isShowingLabels);

      wrapper.findComponent(GlToggle).vm.$emit('change');

      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'click_toggle_labels_on_merge_request_dashboard',
        {
          label: 'show_labels',
          property,
        },
        undefined,
      );
    },
  );

  it.each`
    isShowingLabels | mutationValue
    ${false}        | ${true}
    ${true}         | ${false}
  `(
    'mutates apollo cache on GlDisclosureDropdownItem action event with isShowingLabels value as $mutationValue',
    async ({ isShowingLabels, mutationValue }) => {
      createComponent(isShowingLabels);

      wrapper.findComponent(GlToggle).vm.$emit('change');

      await nextTick();

      expect(setIsShowingLabelsMutationMock).toHaveBeenCalledWith(
        {},
        {
          isShowingLabels: mutationValue,
        },
        expect.anything(),
        expect.anything(),
      );
    },
  );

  it.each`
    mergeRequestDashboardListType
    ${'role_based'}
    ${'list_baed'}
  `(
    'sends mutation query when select event is triggered on dropdown',
    async ({ mergeRequestDashboardListType }) => {
      createComponent();

      findDropdown().vm.$emit('select', mergeRequestDashboardListType);

      await waitForPromises();

      expect(updatePreferencesMutationMock).toHaveBeenCalledWith({
        mergeRequestDashboardListType: mergeRequestDashboardListType.toUpperCase(),
      });
    },
  );

  it.each`
    mergeRequestDashboardListType
    ${'role_based'}
    ${'list_baed'}
  `(
    'sends tracking event when select event is triggered on dropdown',
    async ({ mergeRequestDashboardListType }) => {
      createComponent();

      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findDropdown().vm.$emit('select', mergeRequestDashboardListType);

      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'toggle_list_type_on_merge_request_homepage',
        {
          property: mergeRequestDashboardListType,
        },
        undefined,
      );
    },
  );
});
