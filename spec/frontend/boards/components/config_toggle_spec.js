import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import ConfigToggle from '~/boards/components/config_toggle.vue';
import { mockTracking } from 'helpers/tracking_helper';

describe('ConfigToggle', () => {
  let wrapper;

  const createComponent = (provide = {}, props = {}) =>
    shallowMount(ConfigToggle, {
      provide: {
        canAdminList: true,
        ...provide,
      },
      propsData: props,
    });

  const findButton = () => wrapper.findComponent(GlButton);

  it('renders a button with label `Board configuration` when `canAdminList` is `false`', () => {
    wrapper = createComponent({ canAdminList: false });
    expect(findButton().attributes('title')).toBe('Board configuration');
  });

  it('renders a button with label `Configure board` when `canAdminList` is `true`', () => {
    wrapper = createComponent();
    expect(findButton().element.title).toBe('Configure board');
  });

  it('emits `showBoardModal` when button is clicked', () => {
    wrapper = createComponent();

    findButton().vm.$emit('click', { preventDefault: () => {} });

    expect(wrapper.emitted('showBoardModal')).toEqual([['edit']]);
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
