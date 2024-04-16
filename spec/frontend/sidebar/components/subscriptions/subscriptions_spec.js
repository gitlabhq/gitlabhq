import { GlToggle } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import Subscriptions from '~/sidebar/components/subscriptions/subscriptions.vue';
import eventHub from '~/sidebar/event_hub';

describe('Subscriptions', () => {
  let wrapper;
  let trackingSpy;

  const findToggleButton = () => wrapper.findComponent(GlToggle);
  const findTooltip = () => wrapper.findComponent({ ref: 'tooltip' });

  const mountComponent = (propsData) => {
    wrapper = shallowMountExtended(Subscriptions, {
      propsData,
    });
  };

  it('shows loading spinner when loading', () => {
    mountComponent({
      loading: true,
      subscribed: undefined,
    });

    expect(findToggleButton().props('isLoading')).toBe(true);
  });

  it('is toggled "off" when currently not subscribed', () => {
    mountComponent({
      subscribed: false,
    });

    expect(findToggleButton().props('value')).toBe(false);
  });

  it('is toggled "on" when currently subscribed', () => {
    mountComponent({
      subscribed: true,
    });

    expect(findToggleButton().props('value')).toBe(true);
  });

  it('toggleSubscription method emits `toggleSubscription` event on eventHub and Component', () => {
    const id = 42;
    mountComponent({ subscribed: true, id });
    const eventHubSpy = jest.spyOn(eventHub, '$emit');

    findToggleButton().vm.$emit('change');

    expect(eventHubSpy).toHaveBeenCalledWith('toggleSubscription', id);
    expect(wrapper.emitted('toggleSubscription')).toEqual([[id]]);
  });

  it('tracks the event when toggled', () => {
    trackingSpy = mockTracking('_category_', undefined, jest.spyOn);
    mountComponent({ subscribed: true });

    findToggleButton().vm.$emit('change');

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'toggle_button', {
      category: undefined,
      label: 'right_sidebar',
      property: 'notifications',
      value: 0,
    });
  });

  it('onClickCollapsedIcon method emits `toggleSidebar` event on component', () => {
    mountComponent({ subscribed: true });
    findTooltip().trigger('click');

    expect(wrapper.emitted('toggleSidebar')).toHaveLength(1);
  });

  it('has visually hidden label', () => {
    mountComponent();

    expect(findToggleButton().props()).toMatchObject({
      label: 'Notifications',
      labelPosition: 'hidden',
    });
  });

  describe('given project emails are disabled', () => {
    const subscribeDisabledDescription = 'Notifications have been disabled';

    beforeEach(() => {
      mountComponent({
        subscribed: false,
        projectEmailsEnabled: false,
        subscribeDisabledDescription,
      });
    });

    it('sets the correct display text', () => {
      expect(wrapper.findByTestId('subscription-title').text()).toContain(
        subscribeDisabledDescription,
      );
      expect(findTooltip().attributes('title')).toBe(subscribeDisabledDescription);
    });

    it('does not render the toggle button', () => {
      expect(findToggleButton().exists()).toBe(false);
    });
  });
});
