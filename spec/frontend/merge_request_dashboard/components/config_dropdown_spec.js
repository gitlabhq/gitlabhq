import Vue, { nextTick } from 'vue';
import { GlToggle } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import ConfigDropdown from '~/merge_request_dashboard/components/config_dropdown.vue';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';

Vue.use(VueApollo);

describe('Merge request dashboard config dropdown component', () => {
  let wrapper;
  let setIsShowingLabelsMutationMock;

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  function createComponent(isShowingLabels = false) {
    setIsShowingLabelsMutationMock = jest.fn();
    const resolvers = {
      Mutation: {
        setIsShowingLabels: setIsShowingLabelsMutationMock,
      },
    };

    const apolloProvider = createMockApollo([], resolvers);

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
});
