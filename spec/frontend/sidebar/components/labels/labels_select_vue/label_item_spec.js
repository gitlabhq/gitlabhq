import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import LabelItem from '~/sidebar/components/labels/labels_select_vue/label_item.vue';
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

  describe('template', () => {
    it('renders gl-link component', () => {
      expect(wrapper.findComponent(GlLink).exists()).toBe(true);
    });

    it('renders component root with class `is-focused` when `highlight` prop is true', () => {
      const wrapperTemp = createComponent({
        highlight: true,
      });

      expect(wrapperTemp.classes()).toContain('is-focused');

      wrapperTemp.destroy();
    });

    it.each`
      isLabelSet | isLabelIndeterminate | testId                  | iconName
      ${true}    | ${false}             | ${'checked-icon'}       | ${'mobile-issue-close'}
      ${false}   | ${true}              | ${'indeterminate-icon'} | ${'dash'}
    `(
      'renders visible gl-icon component when `isLabelSet` prop is $isLabelSet and `isLabelIndeterminate` is $isLabelIndeterminate',
      ({ isLabelSet, isLabelIndeterminate, testId, iconName }) => {
        const wrapperTemp = createComponent({
          isLabelSet,
          isLabelIndeterminate,
        });

        const iconEl = wrapperTemp.find(`[data-testid="${testId}"]`);

        expect(iconEl.isVisible()).toBe(true);
        expect(iconEl.props('name')).toBe(iconName);

        wrapperTemp.destroy();
      },
    );

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
