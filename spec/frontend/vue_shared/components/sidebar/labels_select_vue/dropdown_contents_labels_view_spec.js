import {
  GlIntersectionObserver,
  GlButton,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlLink,
} from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { UP_KEY_CODE, DOWN_KEY_CODE, ENTER_KEY_CODE, ESC_KEY_CODE } from '~/lib/utils/keycodes';
import DropdownContentsLabelsView from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_contents_labels_view.vue';
import LabelItem from '~/vue_shared/components/sidebar/labels_select_vue/label_item.vue';

import * as actions from '~/vue_shared/components/sidebar/labels_select_vue/store/actions';
import * as getters from '~/vue_shared/components/sidebar/labels_select_vue/store/getters';
import mutations from '~/vue_shared/components/sidebar/labels_select_vue/store/mutations';
import defaultState from '~/vue_shared/components/sidebar/labels_select_vue/store/state';

import { mockConfig, mockLabels, mockRegularLabel } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('DropdownContentsLabelsView', () => {
  let wrapper;

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

    wrapper = shallowMount(DropdownContentsLabelsView, {
      localVue,
      store,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findDropdownContent = () => wrapper.find('[data-testid="dropdown-content"]');
  const findDropdownTitle = () => wrapper.find('[data-testid="dropdown-title"]');
  const findDropdownFooter = () => wrapper.find('[data-testid="dropdown-footer"]');
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  describe('computed', () => {
    describe('visibleLabels', () => {
      it('returns matching labels filtered with `searchKey`', () => {
        wrapper.setData({
          searchKey: 'bug',
        });

        expect(wrapper.vm.visibleLabels.length).toBe(1);
        expect(wrapper.vm.visibleLabels[0].title).toBe('Bug');
      });

      it('returns matching labels with fuzzy filtering', () => {
        wrapper.setData({
          searchKey: 'bg',
        });

        expect(wrapper.vm.visibleLabels.length).toBe(2);
        expect(wrapper.vm.visibleLabels[0].title).toBe('Bug');
        expect(wrapper.vm.visibleLabels[1].title).toBe('Boog');
      });

      it('returns all labels when `searchKey` is empty', () => {
        wrapper.setData({
          searchKey: '',
        });

        expect(wrapper.vm.visibleLabels.length).toBe(mockLabels.length);
      });
    });

    describe('showNoMatchingResultsMessage', () => {
      it.each`
        searchKey | labels        | labelsDescription | returnValue
        ${''}     | ${[]}         | ${'empty'}        | ${false}
        ${'bug'}  | ${[]}         | ${'empty'}        | ${true}
        ${''}     | ${mockLabels} | ${'not empty'}    | ${false}
        ${'bug'}  | ${mockLabels} | ${'not empty'}    | ${false}
      `(
        'returns $returnValue when searchKey is "$searchKey" and visibleLabels is $labelsDescription',
        async ({ searchKey, labels, returnValue }) => {
          wrapper.setData({
            searchKey,
          });

          wrapper.vm.$store.dispatch('receiveLabelsSuccess', labels);

          await wrapper.vm.$nextTick();

          expect(wrapper.vm.showNoMatchingResultsMessage).toBe(returnValue);
        },
      );
    });
  });

  describe('methods', () => {
    const fakePreventDefault = jest.fn();

    describe('isLabelSelected', () => {
      it('returns true when provided `label` param is one of the selected labels', () => {
        expect(wrapper.vm.isLabelSelected(mockRegularLabel)).toBe(true);
      });

      it('returns false when provided `label` param is not one of the selected labels', () => {
        expect(wrapper.vm.isLabelSelected(mockLabels[2])).toBe(false);
      });
    });

    describe('handleComponentAppear', () => {
      it('calls `focusInput` on searchInput field', async () => {
        wrapper.vm.$refs.searchInput.focusInput = jest.fn();

        await wrapper.vm.handleComponentAppear();

        expect(wrapper.vm.$refs.searchInput.focusInput).toHaveBeenCalled();
      });
    });

    describe('handleComponentDisappear', () => {
      it('calls action `receiveLabelsSuccess` with empty array', () => {
        jest.spyOn(wrapper.vm, 'receiveLabelsSuccess');

        wrapper.vm.handleComponentDisappear();

        expect(wrapper.vm.receiveLabelsSuccess).toHaveBeenCalledWith([]);
      });
    });

    describe('handleCreateLabelClick', () => {
      it('calls actions `receiveLabelsSuccess` with empty array and `toggleDropdownContentsCreateView`', () => {
        jest.spyOn(wrapper.vm, 'receiveLabelsSuccess');
        jest.spyOn(wrapper.vm, 'toggleDropdownContentsCreateView');

        wrapper.vm.handleCreateLabelClick();

        expect(wrapper.vm.receiveLabelsSuccess).toHaveBeenCalledWith([]);
        expect(wrapper.vm.toggleDropdownContentsCreateView).toHaveBeenCalled();
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

      it('resets the search text when the Enter key is pressed', () => {
        wrapper.setData({
          currentHighlightItem: 1,
          searchKey: 'bug',
        });

        wrapper.vm.handleKeyDown({
          keyCode: ENTER_KEY_CODE,
          preventDefault: fakePreventDefault,
        });

        expect(wrapper.vm.searchKey).toBe('');
        expect(fakePreventDefault).toHaveBeenCalled();
      });

      it('calls action `updateSelectedLabels` with currently highlighted label when Enter key is pressed', () => {
        jest.spyOn(wrapper.vm, 'updateSelectedLabels').mockImplementation();
        wrapper.setData({
          currentHighlightItem: 1,
        });

        wrapper.vm.handleKeyDown({
          keyCode: ENTER_KEY_CODE,
          preventDefault: fakePreventDefault,
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
    it('renders gl-intersection-observer as component root', () => {
      expect(wrapper.find(GlIntersectionObserver).exists()).toBe(true);
    });

    it('renders gl-loading-icon component when `labelsFetchInProgress` prop is true', () => {
      wrapper.vm.$store.dispatch('requestLabels');

      return wrapper.vm.$nextTick(() => {
        const loadingIconEl = findLoadingIcon();

        expect(loadingIconEl.exists()).toBe(true);
        expect(loadingIconEl.attributes('class')).toContain('labels-fetch-loading');
      });
    });

    it('renders dropdown title element', () => {
      const titleEl = findDropdownTitle();

      expect(titleEl.exists()).toBe(true);
      expect(titleEl.text()).toBe('Assign labels');
    });

    it('does not render dropdown title element when `state.variant` is "standalone"', () => {
      createComponent({ ...mockConfig, variant: 'standalone' });
      expect(findDropdownTitle().exists()).toBe(false);
    });

    it('renders dropdown title element when `state.variant` is "embedded"', () => {
      createComponent({ ...mockConfig, variant: 'embedded' });
      expect(findDropdownTitle().exists()).toBe(true);
    });

    it('renders dropdown close button element', () => {
      const closeButtonEl = findDropdownTitle().find(GlButton);

      expect(closeButtonEl.exists()).toBe(true);
      expect(closeButtonEl.props('icon')).toBe('close');
    });

    it('renders label search input element', () => {
      const searchInputEl = wrapper.find(GlSearchBoxByType);

      expect(searchInputEl.exists()).toBe(true);
    });

    it('renders label elements for all labels', () => {
      expect(wrapper.findAll(LabelItem)).toHaveLength(mockLabels.length);
    });

    it('renders label element with `highlight` set to true when value of `currentHighlightItem` is more than -1', () => {
      wrapper.setData({
        currentHighlightItem: 0,
      });

      return wrapper.vm.$nextTick(() => {
        const labelItemEl = findDropdownContent().find(LabelItem);

        expect(labelItemEl.attributes('highlight')).toBe('true');
      });
    });

    it('renders element containing "No matching results" when `searchKey` does not match with any label', () => {
      wrapper.setData({
        searchKey: 'abc',
      });

      return wrapper.vm.$nextTick(() => {
        const noMatchEl = findDropdownContent().find('li');

        expect(noMatchEl.isVisible()).toBe(true);
        expect(noMatchEl.text()).toContain('No matching results');
      });
    });

    it('renders empty content while loading', () => {
      wrapper.vm.$store.state.labelsFetchInProgress = true;

      return wrapper.vm.$nextTick(() => {
        const dropdownContent = findDropdownContent();
        const loadingIcon = findLoadingIcon();

        expect(dropdownContent.exists()).toBe(true);
        expect(dropdownContent.isVisible()).toBe(true);
        expect(loadingIcon.exists()).toBe(true);
        expect(loadingIcon.isVisible()).toBe(true);
      });
    });

    it('renders footer list items', () => {
      const footerLinks = findDropdownFooter().findAll(GlLink);
      const createLabelLink = footerLinks.at(0);
      const manageLabelsLink = footerLinks.at(1);

      expect(createLabelLink.exists()).toBe(true);
      expect(createLabelLink.text()).toBe('Create label');
      expect(manageLabelsLink.exists()).toBe(true);
      expect(manageLabelsLink.text()).toBe('Manage labels');
    });

    it('does not render "Create label" footer link when `state.allowLabelCreate` is `false`', () => {
      wrapper.vm.$store.state.allowLabelCreate = false;

      return wrapper.vm.$nextTick(() => {
        const createLabelLink = findDropdownFooter().findAll(GlLink).at(0);

        expect(createLabelLink.text()).not.toBe('Create label');
      });
    });

    it('does not render footer list items when `state.variant` is "standalone"', () => {
      createComponent({ ...mockConfig, variant: 'standalone' });
      expect(findDropdownFooter().exists()).toBe(false);
    });

    it('does not render footer list items when `allowLabelCreate` is false and `labelsManagePath` is null', () => {
      createComponent({
        ...mockConfig,
        allowLabelCreate: false,
        labelsManagePath: null,
      });
      expect(findDropdownFooter().exists()).toBe(false);
    });

    it('renders footer list items when `state.variant` is "embedded"', () => {
      expect(findDropdownFooter().exists()).toBe(true);
    });
  });
});
