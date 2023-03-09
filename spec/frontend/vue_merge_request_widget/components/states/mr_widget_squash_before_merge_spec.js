import { GlFormCheckbox, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SquashBeforeMerge from '~/vue_merge_request_widget/components/states/squash_before_merge.vue';
import { SQUASH_BEFORE_MERGE } from '~/vue_merge_request_widget/i18n';

describe('Squash before merge component', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(SquashBeforeMerge, {
      propsData: {
        ...props,
      },
    });
  };

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  describe('checkbox', () => {
    it('is unchecked if passed value prop is false', () => {
      createComponent({
        value: false,
      });

      expect(findCheckbox().vm.$attrs.checked).toBe(false);
    });

    it('is checked if passed value prop is true', () => {
      createComponent({
        value: true,
      });

      expect(findCheckbox().vm.$attrs.checked).toBe(true);
    });

    it('is disabled if isDisabled prop is true', () => {
      createComponent({
        value: false,
        isDisabled: true,
      });

      expect(findCheckbox().vm.$attrs.disabled).toBe(true);
    });
  });

  describe('tooltip', () => {
    const tooltipTitle = () => findCheckbox().attributes('title');

    it('does not render when isDisabled is false', () => {
      createComponent({
        value: true,
        isDisabled: false,
      });
      expect(tooltipTitle()).toBeUndefined();
    });

    it('display message when when isDisabled is true', () => {
      createComponent({
        value: true,
        isDisabled: true,
      });

      expect(tooltipTitle()).toBe(SQUASH_BEFORE_MERGE.tooltipTitle);
    });
  });

  describe('about link', () => {
    it('is not rendered if no help path is passed', () => {
      createComponent({
        value: false,
      });

      const aboutLink = wrapper.findComponent(GlLink);

      expect(aboutLink.exists()).toBe(false);
    });

    it('is rendered if  help path is passed', () => {
      createComponent({
        value: false,
        helpPath: 'test-path',
      });

      const aboutLink = wrapper.findComponent(GlLink);

      expect(aboutLink.exists()).toBe(true);
    });

    it('should have a correct help path if passed', () => {
      createComponent({
        value: false,
        helpPath: 'test-path',
      });

      const aboutLink = wrapper.findComponent(GlLink);

      expect(aboutLink.attributes('href')).toEqual('test-path');
    });
  });
});
