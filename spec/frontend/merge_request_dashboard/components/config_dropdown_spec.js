import Vue, { nextTick } from 'vue';
import { GlCollapsibleListbox, GlPopover } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import ConfigDropdown from '~/merge_request_dashboard/components/config_dropdown.vue';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import currentUserPreferencesQuery from '~/merge_request_dashboard/queries/current_user_preferences.query.graphql';
import updatePreferencesMutation from '~/merge_request_dashboard/queries/update_preferences.mutation.graphql';

Vue.use(VueApollo);

describe('Merge request dashboard config dropdown component', () => {
  let wrapper;
  let setIsShowingLabelsMutationMock;
  let updatePreferencesMutationMock;
  let userCalloutDismissSpy;

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findDraftsToggle = () => wrapper.findByTestId('show-drafts-toggle');
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  function createComponent({ isShowingLabels = false, shouldShowCallout = true } = {}) {
    setIsShowingLabelsMutationMock = jest.fn();
    updatePreferencesMutationMock = jest.fn().mockResolvedValue({
      data: {
        userPreferencesUpdate: {
          userPreferences: {
            mergeRequestDashboardListType: 'ROLE_BASED',
            mergeRequestDashboardShowDrafts: true,
          },
        },
      },
    });
    const resolvers = {
      Mutation: {
        setIsShowingLabels: setIsShowingLabelsMutationMock,
      },
    };

    const apolloProvider = createMockApollo(
      [
        [updatePreferencesMutation, updatePreferencesMutationMock],
        [
          currentUserPreferencesQuery,
          jest.fn().mockResolvedValue({
            data: {
              currentUser: {
                id: 1,
                userPreferences: { listType: 'role_based', showDrafts: true },
              },
            },
          }),
        ],
      ],
      resolvers,
    );

    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: isShowingLabelsQuery,
      data: {
        isShowingLabels,
      },
    });

    userCalloutDismissSpy = jest.fn();

    wrapper = shallowMountExtended(ConfigDropdown, {
      apolloProvider,
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
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

      createComponent({ isShowingLabels });

      wrapper.findByTestId('show-labels-toggle').vm.$emit('change');

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
      createComponent({ isShowingLabels });

      wrapper.findByTestId('show-labels-toggle').vm.$emit('change');

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

  it('triggers mutation when toggling show drafts toggle', async () => {
    createComponent();

    findDraftsToggle().vm.$emit('change', false);

    await nextTick();

    expect(updatePreferencesMutationMock).toHaveBeenCalledWith({
      mergeRequestDashboardShowDrafts: false,
    });
  });

  it('set isLoading prop on drafts toggle', async () => {
    createComponent();

    findDraftsToggle().vm.$emit('change', false);

    await nextTick();

    expect(findDraftsToggle().props('isLoading')).toBe(true);
  });

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

  it('displays explanation popover when shouldShowCallout is true', () => {
    createComponent({ shouldShowCallout: true });

    expect(findPopover().exists()).toBe(true);
  });

  it('does not display explanation popover when shouldShowCallout is false', () => {
    createComponent({ shouldShowCallout: false });

    expect(findPopover().exists()).toBe(false);
  });

  it('calls dismiss method when hiding popover', () => {
    createComponent({ shouldShowCallout: true });

    findPopover().vm.$emit('hidden');

    expect(userCalloutDismissSpy).toHaveBeenCalled();
  });
});
