import { mount } from '@vue/test-utils';
import { GlLabel } from '@gitlab/ui';
import DropdownValueComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_value.vue';

import { mockConfig, mockLabels } from './mock_data';

const createComponent = (
  labels = mockLabels,
  labelFilterBasePath = mockConfig.labelFilterBasePath,
) =>
  mount(DropdownValueComponent, {
    propsData: {
      labels,
      labelFilterBasePath,
      enableScopedLabels: true,
    },
    stubs: {
      GlLabel: true,
    },
  });

describe('DropdownValueComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.destroy();
  });

  describe('computed', () => {
    describe('isEmpty', () => {
      it('returns true if `labels` prop is empty', () => {
        const vmEmptyLabels = createComponent([]);

        expect(vmEmptyLabels.classes()).not.toContain('has-labels');
        vmEmptyLabels.destroy();
      });

      it('returns false if `labels` prop is empty', () => {
        expect(vm.classes()).toContain('has-labels');
      });
    });
  });

  describe('methods', () => {
    describe('labelFilterUrl', () => {
      it('returns URL string starting with labelFilterBasePath and encoded label.title', () => {
        expect(vm.find(GlLabel).props('target')).toBe(
          '/gitlab-org/my-project/issues?label_name[]=Foo%20Label',
        );
      });
    });

    describe('showScopedLabels', () => {
      it('returns true if the label is scoped label', () => {
        const labels = vm.findAll(GlLabel);
        expect(labels.length).toEqual(2);
        expect(labels.at(1).props('scoped')).toBe(true);
      });
    });
  });

  describe('template', () => {
    it('renders component container element with classes `hide-collapsed value issuable-show-labels`', () => {
      expect(vm.classes()).toContain('hide-collapsed', 'value', 'issuable-show-labels');
    });

    it('render slot content inside component when `labels` prop is empty', () => {
      const vmEmptyLabels = createComponent([]);

      expect(
        vmEmptyLabels
          .find('.text-secondary')
          .text()
          .trim(),
      ).toBe(mockConfig.emptyValueText);
      vmEmptyLabels.destroy();
    });

    it('renders DropdownValueComponent element', () => {
      const labelEl = vm.find(GlLabel);

      expect(labelEl.exists()).toBe(true);
    });
  });
});
