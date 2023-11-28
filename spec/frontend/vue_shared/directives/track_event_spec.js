import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Tracking from '~/tracking';
import TrackEvent from '~/vue_shared/directives/track_event';

jest.mock('~/tracking');

describe('TrackEvent directive', () => {
  let wrapper;

  const clickButton = () => wrapper.find('button').trigger('click');

  const DummyTrackComponent = Vue.component('DummyTrackComponent', {
    directives: {
      TrackEvent,
    },
    props: {
      category: {
        type: String,
        required: false,
        default: '',
      },
      action: {
        type: String,
        required: false,
        default: '',
      },
      label: {
        type: String,
        required: false,
        default: '',
      },
    },
    template: '<button v-track-event="{ category, action, label }"></button>',
  });

  const mountComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(DummyTrackComponent, {
      propsData,
    });
  };

  it('does not track the event if required arguments are not provided', () => {
    mountComponent();
    clickButton();

    expect(Tracking.event).not.toHaveBeenCalled();
  });

  it('tracks event on click if tracking info provided', async () => {
    mountComponent({
      propsData: {
        category: 'Tracking',
        action: 'click_trackable_btn',
        label: 'Trackable Info',
      },
    });

    await nextTick();
    clickButton();

    expect(Tracking.event).toHaveBeenCalledWith('Tracking', 'click_trackable_btn', {
      label: 'Trackable Info',
    });
  });
});
