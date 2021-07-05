import { GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import DropdownValue from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_value.vue';

import { mockRegularLabel, mockScopedLabel } from './mock_data';

describe('DropdownValue', () => {
  let wrapper;

  const findAllLabels = () => wrapper.findAllComponents(GlLabel);
  const findRegularLabel = () => findAllLabels().at(0);
  const findScopedLabel = () => findAllLabels().at(1);
  const findWrapper = () => wrapper.find('[data-testid="value-wrapper"]');
  const findEmptyPlaceholder = () => wrapper.find('[data-testid="empty-placeholder"]');

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMount(DropdownValue, {
      slots,
      propsData: {
        selectedLabels: [mockRegularLabel, mockScopedLabel],
        allowLabelRemove: true,
        allowScopedLabels: true,
        labelsFilterBasePath: '/gitlab-org/my-project/issues',
        labelsFilterParam: 'label_name',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when there are no labels', () => {
    beforeEach(() => {
      createComponent(
        {
          selectedLabels: [],
        },
        {
          default: 'None',
        },
      );
    });

    it('does not apply `has-labels` class to the wrapping container', () => {
      expect(findWrapper().classes()).not.toContain('has-labels');
    });

    it('renders an empty placeholder', () => {
      expect(findEmptyPlaceholder().exists()).toBe(true);
      expect(findEmptyPlaceholder().text()).toBe('None');
    });

    it('does not render any labels', () => {
      expect(findAllLabels().length).toBe(0);
    });
  });

  describe('when there are labels', () => {
    beforeEach(() => {
      createComponent();
    });

    it('applies `has-labels` class to the wrapping container', () => {
      expect(findWrapper().classes()).toContain('has-labels');
    });

    it('does not render an empty placeholder', () => {
      expect(findEmptyPlaceholder().exists()).toBe(false);
    });

    it('renders a list of two labels', () => {
      expect(findAllLabels().length).toBe(2);
    });

    it('passes correct props to the regular label', () => {
      expect(findRegularLabel().props('target')).toBe(
        '/gitlab-org/my-project/issues?label_name[]=Foo%20Label',
      );
      expect(findRegularLabel().props('scoped')).toBe(false);
    });

    it('passes correct props to the scoped label', () => {
      expect(findScopedLabel().props('target')).toBe(
        '/gitlab-org/my-project/issues?label_name[]=Foo%3A%3ABar',
      );
      expect(findScopedLabel().props('scoped')).toBe(true);
    });

    it('emits `onLabelRemove` event with the correct ID', () => {
      findRegularLabel().vm.$emit('close');
      expect(wrapper.emitted('onLabelRemove')).toEqual([[mockRegularLabel.id]]);
    });
  });
});
