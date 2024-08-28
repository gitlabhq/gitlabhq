import { shallowMount } from '@vue/test-utils';
import { GlDisclosureDropdown } from '@gitlab/ui';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import ActionDropdown from '~/merge_request_dashboard/components/action_dropdown.vue';

describe('Merge request dashboard action dropdown', () => {
  let wrapper;
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  function createComponent(experimentEnabled) {
    wrapper = shallowMount(ActionDropdown, {
      provide: { experimentEnabled },
    });
  }

  it.each`
    experimentEnabled | value
    ${true}           | ${1}
    ${false}          | ${0}
  `('calls tracking method with value $value', async ({ experimentEnabled, value }) => {
    createComponent(experimentEnabled);

    const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

    await wrapper.findComponent(GlDisclosureDropdown).vm.$emit('action', { id: 0 });

    expect(trackEventSpy).toHaveBeenCalledWith(
      'toggle_merge_request_redesign',
      { value },
      undefined,
    );
  });
});
