import { shallowMount } from '@vue/test-utils';
import LoadingButton from '~/vue_shared/components/loading_button.vue';

const LABEL = 'Hello';

describe('LoadingButton', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(LoadingButton, {
      propsData,
    });
  };
  const findButtonLabel = () => wrapper.find('.js-loading-button-label');
  const findButtonIcon = () => wrapper.find('.js-loading-button-icon');

  describe('loading spinner', () => {
    it('shown when loading', () => {
      buildWrapper({ loading: true });

      expect(findButtonIcon().exists()).toBe(true);
    });
  });

  describe('disabled state', () => {
    it('disabled when loading', () => {
      buildWrapper({ loading: true });
      expect(wrapper.attributes('disabled')).toBe('disabled');
    });

    it('not disabled when normal', () => {
      buildWrapper({ loading: false });

      expect(wrapper.attributes('disabled')).toBe(undefined);
    });
  });

  describe('label', () => {
    it('shown when normal', () => {
      buildWrapper({ loading: false, label: LABEL });
      expect(findButtonLabel().text()).toBe(LABEL);
    });

    it('shown when loading', () => {
      buildWrapper({ loading: false, label: LABEL });
      expect(findButtonLabel().text()).toBe(LABEL);
    });
  });

  describe('container class', () => {
    it('should default to btn btn-align-content', () => {
      buildWrapper();

      expect(wrapper.classes()).toContain('btn');
      expect(wrapper.classes()).toContain('btn-align-content');
    });

    it('should be configurable through props', () => {
      const containerClass = 'test-class';

      buildWrapper({
        containerClass,
      });

      expect(wrapper.classes()).not.toContain('btn');
      expect(wrapper.classes()).not.toContain('btn-align-content');
      expect(wrapper.classes()).toContain(containerClass);
    });
  });

  describe('click callback prop', () => {
    it('calls given callback when normal', () => {
      buildWrapper({
        loading: false,
      });

      wrapper.trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('click')).toBeTruthy();
      });
    });

    it('does not call given callback when disabled because of loading', () => {
      buildWrapper({
        loading: true,
      });

      wrapper.trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('click')).toBeFalsy();
      });
    });
  });
});
