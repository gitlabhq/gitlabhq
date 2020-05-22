import { shallowMount } from '@vue/test-utils';

import { GlIcon, GlLink } from '@gitlab/ui';
import LabelItem from '~/vue_shared/components/sidebar/labels_select_vue/label_item.vue';
import { mockRegularLabel } from './mock_data';

const mockLabel = { ...mockRegularLabel, set: true };

const createComponent = ({ label = mockLabel, highlight = true } = {}) =>
  shallowMount(LabelItem, {
    propsData: {
      label,
      isLabelSet: label.set,
      highlight,
    },
  });

describe('LabelItem', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('labelBoxStyle', () => {
      it('returns an object containing `backgroundColor` based on `label` prop', () => {
        expect(wrapper.vm.labelBoxStyle).toEqual(
          expect.objectContaining({
            backgroundColor: mockLabel.color,
          }),
        );
      });
    });
  });

  describe('watchers', () => {
    describe('isLabelSet', () => {
      it('sets value of `isLabelSet` to `isSet` data prop', () => {
        expect(wrapper.vm.isSet).toBe(true);

        wrapper.setProps({
          isLabelSet: false,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.isSet).toBe(false);
        });
      });
    });
  });

  describe('methods', () => {
    describe('handleClick', () => {
      it('sets value of `isSet` data prop to opposite of its current value', () => {
        wrapper.setData({
          isSet: true,
        });

        wrapper.vm.handleClick();
        expect(wrapper.vm.isSet).toBe(false);
        wrapper.vm.handleClick();
        expect(wrapper.vm.isSet).toBe(true);
      });

      it('emits event `clickLabel` on component with `label` prop as param', () => {
        wrapper.vm.handleClick();

        expect(wrapper.emitted('clickLabel')).toBeTruthy();
        expect(wrapper.emitted('clickLabel')[0]).toEqual([mockLabel]);
      });
    });
  });

  describe('template', () => {
    it('renders gl-link component', () => {
      expect(wrapper.find(GlLink).exists()).toBe(true);
    });

    it('renders gl-link component with class `is-focused` when `highlight` prop is true', () => {
      wrapper.setProps({
        highlight: true,
      });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(GlLink).classes()).toContain('is-focused');
      });
    });

    it('renders visible gl-icon component when `isSet` prop is true', () => {
      wrapper.setData({
        isSet: true,
      });

      return wrapper.vm.$nextTick(() => {
        const iconEl = wrapper.find(GlIcon);

        expect(iconEl.isVisible()).toBe(true);
        expect(iconEl.props('name')).toBe('mobile-issue-close');
      });
    });

    it('renders visible span element as placeholder instead of gl-icon when `isSet` prop is false', () => {
      wrapper.setData({
        isSet: false,
      });

      return wrapper.vm.$nextTick(() => {
        const placeholderEl = wrapper.find('[data-testid="no-icon"]');

        expect(placeholderEl.isVisible()).toBe(true);
      });
    });

    it('renders label color element', () => {
      const colorEl = wrapper.find('[data-testid="label-color-box"]');

      expect(colorEl.exists()).toBe(true);
      expect(colorEl.attributes('style')).toBe('background-color: rgb(186, 218, 85);');
    });

    it('renders label title', () => {
      expect(wrapper.text()).toContain(mockLabel.title);
    });
  });
});
