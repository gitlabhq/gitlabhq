import Vuex from 'vuex';
import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import ConfigToggle from '~/boards/components/config_toggle.vue';
import eventHub from '~/boards/eventhub';
import store from '~/boards/stores';
import { mockTracking } from 'helpers/tracking_helper';

describe('ConfigToggle', () => {
  let wrapper;

  Vue.use(Vuex);

  const createComponent = (provide = {}) =>
    shallowMount(ConfigToggle, {
      store,
      provide: {
        canAdminList: true,
        ...provide,
      },
    });

  const findButton = () => wrapper.findComponent(GlButton);

  it('renders a button with label `View scope` when `canAdminList` is `false`', () => {
    wrapper = createComponent({ canAdminList: false });
    expect(findButton().text()).toBe('View scope');
  });

  it('renders a button with label `Edit board` when `canAdminList` is `true`', () => {
    wrapper = createComponent();
    expect(findButton().text()).toBe('Edit board');
  });

  it('emits `showBoardModal` when button is clicked', () => {
    const eventHubSpy = jest.spyOn(eventHub, '$emit');
    wrapper = createComponent();

    findButton().vm.$emit('click', { preventDefault: () => {} });

    expect(eventHubSpy).toHaveBeenCalledWith('showBoardModal', 'edit');
  });

  it('tracks clicking the button', () => {
    const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    wrapper = createComponent();

    findButton().vm.$emit('click', { preventDefault: () => {} });

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
      label: 'edit_board',
    });
  });
});
