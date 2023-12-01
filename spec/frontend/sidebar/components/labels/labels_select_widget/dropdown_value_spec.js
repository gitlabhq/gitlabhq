import { GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import DropdownValue from '~/sidebar/components/labels/labels_select_widget/dropdown_value.vue';

import { mockRegularLabel, mockScopedLabel, mockLockedLabel } from './mock_data';

describe('DropdownValue', () => {
  let wrapper;

  const findAllLabels = () => wrapper.findAllComponents(GlLabel);
  const findRegularLabel = () => findAllLabels().at(2);
  const findScopedLabel = () => findAllLabels().at(0);
  const findLockedLabel = () => findAllLabels().at(1);
  const findWrapper = () => wrapper.find('[data-testid="value-wrapper"]');
  const findEmptyPlaceholder = () => wrapper.find('[data-testid="empty-placeholder"]');

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMount(DropdownValue, {
      slots,
      propsData: {
        selectedLabels: [mockLockedLabel, mockRegularLabel, mockScopedLabel],
        allowLabelRemove: true,
        labelsFilterBasePath: '/gitlab-org/my-project/issues',
        labelsFilterParam: 'label_name',
        ...props,
      },
      provide: {
        allowScopedLabels: true,
      },
    });
  };

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

    it('renders a list of three labels', () => {
      expect(findAllLabels().length).toBe(3);
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

    it('emits `onCollapsedValueClick` when clicking on collapsed value', () => {
      wrapper.find('.sidebar-collapsed-icon').trigger('click');
      expect(wrapper.emitted('onCollapsedValueClick')).toEqual([[]]);
    });

    it('does not show close button if label is locked', () => {
      createComponent({
        supportsLockOnMerge: true,
      });
      expect(findLockedLabel().props('showCloseButton')).toBe(false);
    });

    it('shows close button if label is not locked', () => {
      createComponent({
        supportsLockOnMerge: true,
      });
      expect(findRegularLabel().props('showCloseButton')).toBe(true);
    });
  });
});
