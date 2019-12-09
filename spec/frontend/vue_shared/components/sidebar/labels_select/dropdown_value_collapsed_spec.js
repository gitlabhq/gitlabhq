import Vue from 'vue';

import mountComponent from 'helpers/vue_mount_component_helper';
import dropdownValueCollapsedComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_value_collapsed.vue';

import { mockLabels } from '../../../../../javascripts/vue_shared/components/sidebar/labels_select/mock_data';

const createComponent = (labels = mockLabels) => {
  const Component = Vue.extend(dropdownValueCollapsedComponent);

  return mountComponent(Component, {
    labels,
  });
};

describe('DropdownValueCollapsedComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('labelsList', () => {
      it('returns default text when `labels` prop is empty array', () => {
        const vmEmptyLabels = createComponent([]);

        expect(vmEmptyLabels.labelsList).toBe('Labels');
        vmEmptyLabels.$destroy();
      });

      it('returns labels names separated by coma when `labels` prop has more than one item', () => {
        const labels = mockLabels.concat(mockLabels);
        const vmMoreLabels = createComponent(labels);

        const expectedText = labels.map(label => label.title).join(', ');

        expect(vmMoreLabels.labelsList).toBe(expectedText);
        vmMoreLabels.$destroy();
      });

      it('returns labels names separated by coma with remaining labels count and `and more` phrase when `labels` prop has more than five items', () => {
        const mockMoreLabels = Object.assign([], mockLabels);
        for (let i = 0; i < 6; i += 1) {
          mockMoreLabels.unshift(mockLabels[0]);
        }

        const vmMoreLabels = createComponent(mockMoreLabels);

        const expectedText = `${mockMoreLabels
          .slice(0, 5)
          .map(label => label.title)
          .join(', ')}, and ${mockMoreLabels.length - 5} more`;

        expect(vmMoreLabels.labelsList).toBe(expectedText);
        vmMoreLabels.$destroy();
      });

      it('returns first label name when `labels` prop has only one item present', () => {
        const text = mockLabels.map(label => label.title).join(', ');

        expect(vm.labelsList).toBe(text);
      });
    });
  });

  describe('methods', () => {
    describe('handleClick', () => {
      it('emits onValueClick event on component', () => {
        jest.spyOn(vm, '$emit').mockImplementation(() => {});
        vm.handleClick();

        expect(vm.$emit).toHaveBeenCalledWith('onValueClick');
      });
    });
  });

  describe('template', () => {
    it('renders component container element with tooltip`', () => {
      expect(vm.$el.dataset.placement).toBe('left');
      expect(vm.$el.dataset.container).toBe('body');
      expect(vm.$el.dataset.originalTitle).toBe(vm.labelsList);
    });

    it('renders tags icon element', () => {
      expect(vm.$el.querySelector('.fa-tags')).not.toBeNull();
    });

    it('renders labels count', () => {
      expect(vm.$el.querySelector('span').innerText.trim()).toBe(`${vm.labels.length}`);
    });
  });
});
