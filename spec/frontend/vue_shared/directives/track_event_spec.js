import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Tracking from '~/tracking';
import TrackEvent from '~/vue_shared/directives/track_event';

jest.mock('~/tracking');

describe('TrackEvent directive', () => {
  let wrapper;

  const clickButton = () => wrapper.find('button').trigger('click');

  const createComponent = (trackingOptions) =>
    Vue.component('DummyElement', {
      directives: {
        TrackEvent,
      },
      data() {
        return {
          trackingOptions,
        };
      },
      template: '<button v-track-event="trackingOptions"></button>',
    });

  const mountComponent = (trackingOptions) => shallowMount(createComponent(trackingOptions));

  it('does not track the event if required arguments are not provided', () => {
    wrapper = mountComponent();
    clickButton();

    expect(Tracking.event).not.toHaveBeenCalled();
  });

  it('tracks event on click if tracking info provided', () => {
    wrapper = mountComponent({
      category: 'Tracking',
      action: 'click_trackable_btn',
      label: 'Trackable Info',
    });
    clickButton();

    expect(Tracking.event).toHaveBeenCalledWith('Tracking', 'click_trackable_btn', {
      label: 'Trackable Info',
    });
  });
});
