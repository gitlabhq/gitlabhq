import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import LabelItem from '~/vue_shared/components/sidebar/labels_select_widget/label_item.vue';
import { mockRegularLabel } from './mock_data';

const mockLabel = { ...mockRegularLabel, set: true };

const createComponent = ({
  label = mockLabel,
  isLabelSet = mockLabel.set,
  highlight = true,
} = {}) =>
  shallowMount(LabelItem, {
    propsData: {
      label,
      isLabelSet,
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

  describe('template', () => {
    it('renders gl-link component', () => {
      expect(wrapper.find(GlLink).exists()).toBe(true);
    });

    it('renders component root with class `is-focused` when `highlight` prop is true', () => {
      const wrapperTemp = createComponent({
        highlight: true,
      });

      expect(wrapperTemp.classes()).toContain('is-focused');

      wrapperTemp.destroy();
    });

    it('renders visible gl-icon component when `isLabelSet` prop is true', () => {
      const wrapperTemp = createComponent({
        isLabelSet: true,
      });

      const iconEl = wrapperTemp.find(GlIcon);

      expect(iconEl.isVisible()).toBe(true);
      expect(iconEl.props('name')).toBe('mobile-issue-close');

      wrapperTemp.destroy();
    });

    it('renders visible span element as placeholder instead of gl-icon when `isLabelSet` prop is false', () => {
      const wrapperTemp = createComponent({
        isLabelSet: false,
      });

      const placeholderEl = wrapperTemp.find('[data-testid="no-icon"]');

      expect(placeholderEl.isVisible()).toBe(true);

      wrapperTemp.destroy();
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
