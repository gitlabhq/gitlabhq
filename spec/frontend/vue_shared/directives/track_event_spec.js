import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Tracking from '~/tracking';
import TrackEvent from '~/vue_shared/directives/track_event';

jest.mock('~/tracking');

const Component = Vue.component('DummyElement', {
  directives: {
    TrackEvent,
  },
  data() {
    return {
      trackingOptions: null,
    };
  },
  template: '<button id="trackable" v-track-event="trackingOptions"></button>',
});

let wrapper;
let button;

describe('Error Tracking directive', () => {
  beforeEach(() => {
    wrapper = shallowMount(Component);
    button = wrapper.find('#trackable');
  });

  it('should not track the event if required arguments are not provided', () => {
    button.trigger('click');
    expect(Tracking.event).not.toHaveBeenCalled();
  });

  it('should track event on click if tracking info provided', async () => {
    const trackingOptions = {
      category: 'Tracking',
      action: 'click_trackable_btn',
      label: 'Trackable Info',
    };

    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    wrapper.setData({ trackingOptions });
    const { category, action, label, property, value } = trackingOptions;

    await nextTick();
    button.trigger('click');
    expect(Tracking.event).toHaveBeenCalledWith(category, action, { label, property, value });
  });
});
