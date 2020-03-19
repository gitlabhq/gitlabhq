import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import { GlButton, GlLoadingIcon, GlIcon, GlSearchBoxByType, GlLink } from '@gitlab/ui';
import { UP_KEY_CODE, DOWN_KEY_CODE, ENTER_KEY_CODE, ESC_KEY_CODE } from '~/lib/utils/keycodes';
import DropdownContentsLabelsView from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_contents_labels_view.vue';

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

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
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
    describe('getDropdownLabelBoxStyle', () => {
      it('returns an object containing `backgroundColor` based on provided `label` param', () => {
        expect(wrapper.vm.getDropdownLabelBoxStyle(mockRegularLabel)).toEqual(
          expect.objectContaining({
            backgroundColor: mockRegularLabel.color,
          }),
        );
      });
    });

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
      it('calls action `updateSelectedLabels` with provided `label` param', () => {
        jest.spyOn(wrapper.vm, 'updateSelectedLabels').mockImplementation();

        wrapper.vm.handleLabelClick(mockRegularLabel);

        expect(wrapper.vm.updateSelectedLabels).toHaveBeenCalledWith([mockRegularLabel]);
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

    it('renders dropdown close button element', () => {
      const closeButtonEl = wrapper.find('.dropdown-title').find(GlButton);

      expect(closeButtonEl.exists()).toBe(true);
      expect(closeButtonEl.find(GlIcon).exists()).toBe(true);
      expect(closeButtonEl.find(GlIcon).props('name')).toBe('close');
    });

    it('renders label search input element', () => {
      const searchInputEl = wrapper.find(GlSearchBoxByType);

      expect(searchInputEl.exists()).toBe(true);
      expect(searchInputEl.attributes('autofocus')).toBe('true');
    });

    it('renders label elements for all labels', () => {
      const labelsEl = wrapper.findAll('.dropdown-content li');
      const labelItemEl = labelsEl.at(0).find(GlLink);

      expect(labelsEl.length).toBe(mockLabels.length);
      expect(labelItemEl.exists()).toBe(true);
      expect(labelItemEl.find(GlIcon).props('name')).toBe('mobile-issue-close');
      expect(labelItemEl.find('.dropdown-label-box').attributes('style')).toBe(
        'background-color: rgb(186, 218, 85);',
      );
      expect(labelItemEl.find(GlLink).text()).toContain(mockLabels[0].title);
    });

    it('renders label element with "is-focused" when value of `currentHighlightItem` is more than -1', () => {
      wrapper.setData({
        currentHighlightItem: 0,
      });

      return wrapper.vm.$nextTick(() => {
        const labelsEl = wrapper.findAll('.dropdown-content li');
        const labelItemEl = labelsEl.at(0).find(GlLink);

        expect(labelItemEl.attributes('class')).toContain('is-focused');
      });
    });

    it('renders element containing "No matching results" when `searchKey` does not match with any label', () => {
      wrapper.setData({
        searchKey: 'abc',
      });

      return wrapper.vm.$nextTick(() => {
        const noMatchEl = wrapper.find('.dropdown-content li');

        expect(noMatchEl.exists()).toBe(true);
        expect(noMatchEl.text()).toContain('No matching results');
      });
    });

    it('renders footer list items', () => {
      const createLabelBtn = wrapper.find('.dropdown-footer').find(GlButton);
      const manageLabelsLink = wrapper.find('.dropdown-footer').find(GlLink);

      expect(createLabelBtn.exists()).toBe(true);
      expect(createLabelBtn.text()).toBe('Create label');
      expect(manageLabelsLink.exists()).toBe(true);
      expect(manageLabelsLink.text()).toBe('Manage labels');
    });
  });
});
