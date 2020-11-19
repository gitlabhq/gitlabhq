import { shallowMount } from '@vue/test-utils';
import Subscriptions from '~/sidebar/components/subscriptions/subscriptions.vue';
import eventHub from '~/sidebar/event_hub';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';

describe('Subscriptions', () => {
  let wrapper;

  const findToggleButton = () => wrapper.find(ToggleButton);

  const mountComponent = propsData =>
    shallowMount(Subscriptions, {
      propsData,
    });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('shows loading spinner when loading', () => {
    wrapper = mountComponent({
      loading: true,
      subscribed: undefined,
    });

    expect(findToggleButton().attributes('isloading')).toBe('true');
  });

  it('is toggled "off" when currently not subscribed', () => {
    wrapper = mountComponent({
      subscribed: false,
    });

    expect(findToggleButton().attributes('value')).toBeFalsy();
  });

  it('is toggled "on" when currently subscribed', () => {
    wrapper = mountComponent({
      subscribed: true,
    });

    expect(findToggleButton().attributes('value')).toBe('true');
  });

  it('toggleSubscription method emits `toggleSubscription` event on eventHub and Component', () => {
    const id = 42;
    wrapper = mountComponent({ subscribed: true, id });
    const eventHubSpy = jest.spyOn(eventHub, '$emit');
    const wrapperEmitSpy = jest.spyOn(wrapper.vm, '$emit');

    wrapper.vm.toggleSubscription();

    expect(eventHubSpy).toHaveBeenCalledWith('toggleSubscription', id);
    expect(wrapperEmitSpy).toHaveBeenCalledWith('toggleSubscription', id);
    eventHubSpy.mockRestore();
    wrapperEmitSpy.mockRestore();
  });

  it('tracks the event when toggled', () => {
    wrapper = mountComponent({ subscribed: true });

    const wrapperTrackSpy = jest.spyOn(wrapper.vm, 'track');

    wrapper.vm.toggleSubscription();

    expect(wrapperTrackSpy).toHaveBeenCalledWith('toggle_button', {
      property: 'notifications',
      value: 0,
    });
    wrapperTrackSpy.mockRestore();
  });

  it('onClickCollapsedIcon method emits `toggleSidebar` event on component', () => {
    wrapper = mountComponent({ subscribed: true });
    const spy = jest.spyOn(wrapper.vm, '$emit');

    wrapper.vm.onClickCollapsedIcon();

    expect(spy).toHaveBeenCalledWith('toggleSidebar');
    spy.mockRestore();
  });

  describe('given project emails are disabled', () => {
    const subscribeDisabledDescription = 'Notifications have been disabled';

    beforeEach(() => {
      wrapper = mountComponent({
        subscribed: false,
        projectEmailsDisabled: true,
        subscribeDisabledDescription,
      });
    });

    it('sets the correct display text', () => {
      expect(wrapper.find('.issuable-header-text').text()).toContain(subscribeDisabledDescription);
      expect(wrapper.find({ ref: 'tooltip' }).attributes('title')).toBe(
        subscribeDisabledDescription,
      );
    });

    it('does not render the toggle button', () => {
      expect(wrapper.find('.js-issuable-subscribe-button').exists()).toBe(false);
    });
  });
});
