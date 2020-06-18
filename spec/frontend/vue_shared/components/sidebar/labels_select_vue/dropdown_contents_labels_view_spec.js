import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import { GlButton, GlLoadingIcon, GlSearchBoxByType, GlLink } from '@gitlab/ui';
import { UP_KEY_CODE, DOWN_KEY_CODE, ENTER_KEY_CODE, ESC_KEY_CODE } from '~/lib/utils/keycodes';
import SmartVirtualList from '~/vue_shared/components/smart_virtual_list.vue';
import DropdownContentsLabelsView from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_contents_labels_view.vue';
import LabelItem from '~/vue_shared/components/sidebar/labels_select_vue/label_item.vue';

import defaultState from '~/vue_shared/components/sidebar/labels_select_vue/store/state';
import mutations from '~/vue_shared/components/sidebar/labels_select_vue/store/mutations';
import * as actions from '~/vue_shared/components/sidebar/labels_select_vue/store/actions';
import * as getters from '~/vue_shared/components/sidebar/labels_select_vue/store/getters';

import { mockConfig, mockLabels, mockRegularLabel } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = (initialState = mockConfig) => {
  const store = new Vuex.Store({
    getters,
    mutations,
    state: {
      ...defaultState(),
      footerCreateLabelTitle: 'Create label',
      footerManageLabelTitle: 'Manage labels',
    },
    actions: {
      ...actions,
      fetchLabels: jest.fn(),
    },
  });

  store.dispatch('setInitialState', initialState);
  store.dispatch('receiveLabelsSuccess', mockLabels);

  return shallowMount(DropdownContentsLabelsView, {
    localVue,
    store,
  });
};

describe('DropdownContentsLabelsView', () => {
  let wrapper;
  let wrapperStandalone;

  beforeEach(() => {
    wrapper = createComponent();
    wrapperStandalone = createComponent({
      ...mockConfig,
      variant: 'standalone',
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapperStandalone.destroy();
  });

  describe('computed', () => {
    describe('visibleLabels', () => {
      it('returns matching labels filtered with `searchKey`', () => {
        wrapper.setData({
          searchKey: 'bug',
        });

        expect(wrapper.vm.visibleLabels.length).toBe(1);
        expect(wrapper.vm.visibleLabels[0].title).toBe('Bug');
      });

      it('returns all labels when `searchKey` is empty', () => {
        wrapper.setData({
          searchKey: '',
        });

        expect(wrapper.vm.visibleLabels.length).toBe(mockLabels.length);
      });
    });
  });

  describe('methods', () => {
    describe('isLabelSelected', () => {
      it('returns true when provided `label` param is one of the selected labels', () => {
        expect(wrapper.vm.isLabelSelected(mockRegularLabel)).toBe(true);
      });

      it('returns false when provided `label` param is not one of the selected labels', () => {
        expect(wrapper.vm.isLabelSelected(mockLabels[2])).toBe(false);
      });
    });

    describe('handleKeyDown', () => {
      it('decreases `currentHighlightItem` value by 1 when Up arrow key is pressed', () => {
        wrapper.setData({
          currentHighlightItem: 1,
        });

        wrapper.vm.handleKeyDown({
          keyCode: UP_KEY_CODE,
        });

        expect(wrapper.vm.currentHighlightItem).toBe(0);
      });

      it('increases `currentHighlightItem` value by 1 when Down arrow key is pressed', () => {
        wrapper.setData({
          currentHighlightItem: 1,
        });

        wrapper.vm.handleKeyDown({
          keyCode: DOWN_KEY_CODE,
        });

        expect(wrapper.vm.currentHighlightItem).toBe(2);
      });

      it('calls action `updateSelectedLabels` with currently highlighted label when Enter key is pressed', () => {
        jest.spyOn(wrapper.vm, 'updateSelectedLabels').mockImplementation();
        wrapper.setData({
          currentHighlightItem: 1,
        });

        wrapper.vm.handleKeyDown({
          keyCode: ENTER_KEY_CODE,
        });

        expect(wrapper.vm.updateSelectedLabels).toHaveBeenCalledWith([
          {
            ...mockLabels[1],
            set: true,
          },
        ]);
      });

      it('calls action `toggleDropdownContents` when Esc key is pressed', () => {
        jest.spyOn(wrapper.vm, 'toggleDropdownContents').mockImplementation();
        wrapper.setData({
          currentHighlightItem: 1,
        });

        wrapper.vm.handleKeyDown({
          keyCode: ESC_KEY_CODE,
        });

        expect(wrapper.vm.toggleDropdownContents).toHaveBeenCalled();
      });

      it('calls action `scrollIntoViewIfNeeded` in next tick when any key is pressed', () => {
        jest.spyOn(wrapper.vm, 'scrollIntoViewIfNeeded').mockImplementation();
        wrapper.setData({
          currentHighlightItem: 1,
        });

        wrapper.vm.handleKeyDown({
          keyCode: DOWN_KEY_CODE,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.scrollIntoViewIfNeeded).toHaveBeenCalled();
        });
      });
    });

    describe('handleLabelClick', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'updateSelectedLabels').mockImplementation();
      });

      it('calls action `updateSelectedLabels` with provided `label` param', () => {
        wrapper.vm.handleLabelClick(mockRegularLabel);

        expect(wrapper.vm.updateSelectedLabels).toHaveBeenCalledWith([mockRegularLabel]);
      });

      it('calls action `toggleDropdownContents` when `state.allowMultiselect` is false', () => {
        jest.spyOn(wrapper.vm, 'toggleDropdownContents');
        wrapper.vm.$store.state.allowMultiselect = false;

        wrapper.vm.handleLabelClick(mockRegularLabel);

        expect(wrapper.vm.toggleDropdownContents).toHaveBeenCalled();
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `labels-select-contents-list`', () => {
      expect(wrapper.attributes('class')).toContain('labels-select-contents-list');
    });

    it('renders gl-loading-icon component when `labelsFetchInProgress` prop is true', () => {
      wrapper.vm.$store.dispatch('requestLabels');

      return wrapper.vm.$nextTick(() => {
        const loadingIconEl = wrapper.find(GlLoadingIcon);

        expect(loadingIconEl.exists()).toBe(true);
        expect(loadingIconEl.attributes('class')).toContain('labels-fetch-loading');
      });
    });

    it('renders dropdown title element', () => {
      const titleEl = wrapper.find('.dropdown-title > span');

      expect(titleEl.exists()).toBe(true);
      expect(titleEl.text()).toBe('Assign labels');
    });

    it('does not render dropdown title element when `state.variant` is "standalone"', () => {
      expect(wrapperStandalone.find('.dropdown-title').exists()).toBe(false);
    });

    it('renders dropdown close button element', () => {
      const closeButtonEl = wrapper.find('.dropdown-title').find(GlButton);

      expect(closeButtonEl.exists()).toBe(true);
      expect(closeButtonEl.props('icon')).toBe('close');
    });

    it('renders label search input element', () => {
      const searchInputEl = wrapper.find(GlSearchBoxByType);

      expect(searchInputEl.exists()).toBe(true);
      expect(searchInputEl.attributes('autofocus')).toBe('true');
    });

    it('renders smart-virtual-list element', () => {
      expect(wrapper.find(SmartVirtualList).exists()).toBe(true);
    });

    it('renders label elements for all labels', () => {
      expect(wrapper.findAll(LabelItem)).toHaveLength(mockLabels.length);
    });

    it('renders label element with "is-focused" when value of `currentHighlightItem` is more than -1', () => {
      wrapper.setData({
        currentHighlightItem: 0,
      });

      return wrapper.vm.$nextTick(() => {
        const labelsEl = wrapper.findAll('.dropdown-content li');
        const labelItemEl = labelsEl.at(0).find(LabelItem);

        expect(labelItemEl.props('highlight')).toBe(true);
      });
    });

    it('renders element containing "No matching results" when `searchKey` does not match with any label', () => {
      wrapper.setData({
        searchKey: 'abc',
      });

      return wrapper.vm.$nextTick(() => {
        const noMatchEl = wrapper.find('.dropdown-content li');

        expect(noMatchEl.isVisible()).toBe(true);
        expect(noMatchEl.text()).toContain('No matching results');
      });
    });

    it('renders footer list items', () => {
      const createLabelLink = wrapper
        .find('.dropdown-footer')
        .findAll(GlLink)
        .at(0);
      const manageLabelsLink = wrapper
        .find('.dropdown-footer')
        .findAll(GlLink)
        .at(1);

      expect(createLabelLink.exists()).toBe(true);
      expect(createLabelLink.text()).toBe('Create label');
      expect(manageLabelsLink.exists()).toBe(true);
      expect(manageLabelsLink.text()).toBe('Manage labels');
    });

    it('does not render "Create label" footer link when `state.allowLabelCreate` is `false`', () => {
      wrapper.vm.$store.state.allowLabelCreate = false;

      return wrapper.vm.$nextTick(() => {
        const createLabelLink = wrapper
          .find('.dropdown-footer')
          .findAll(GlLink)
          .at(0);

        expect(createLabelLink.text()).not.toBe('Create label');
      });
    });

    it('does not render footer list items when `state.variant` is "standalone"', () => {
      expect(wrapperStandalone.find('.dropdown-footer').exists()).toBe(false);
    });
  });
});
