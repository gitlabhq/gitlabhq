import { GlLabel } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';

import DropdownValue from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_value.vue';

import labelsSelectModule from '~/vue_shared/components/sidebar/labels_select_vue/store';

import { mockConfig, mockRegularLabel, mockScopedLabel } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('DropdownValue', () => {
  let wrapper;

  const createComponent = (initialState = {}, slots = {}) => {
    const store = new Vuex.Store(labelsSelectModule());

    store.dispatch('setInitialState', { ...mockConfig, ...initialState });

    wrapper = shallowMount(DropdownValue, {
      localVue,
      store,
      slots,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('methods', () => {
    describe('labelFilterUrl', () => {
      it('returns a label filter URL based on provided label param', () => {
        createComponent();

        expect(wrapper.vm.labelFilterUrl(mockRegularLabel)).toBe(
          '/gitlab-org/my-project/issues?label_name[]=Foo%20Label',
        );
      });
    });

    describe('scopedLabel', () => {
      beforeEach(() => {
        createComponent();
      });

      it('returns `true` when provided label param is a scoped label', () => {
        expect(wrapper.vm.scopedLabel(mockScopedLabel)).toBe(true);
      });

      it('returns `false` when provided label param is a regular label', () => {
        expect(wrapper.vm.scopedLabel(mockRegularLabel)).toBe(false);
      });
    });
  });

  describe('template', () => {
    it('renders class `has-labels` on component container element when `selectedLabels` is not empty', () => {
      createComponent();

      expect(wrapper.attributes('class')).toContain('has-labels');
    });

    it('renders element containing `None` when `selectedLabels` is empty', () => {
      createComponent(
        {
          selectedLabels: [],
        },
        {
          default: 'None',
        },
      );
      const noneEl = wrapper.find('span.text-secondary');

      expect(noneEl.exists()).toBe(true);
      expect(noneEl.text()).toBe('None');
    });

    it('renders labels when `selectedLabels` is not empty', () => {
      createComponent();

      expect(wrapper.findAll(GlLabel).length).toBe(2);
    });
  });
});
