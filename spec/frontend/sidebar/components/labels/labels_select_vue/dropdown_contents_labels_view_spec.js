import {
  GlIntersectionObserver,
  GlButton,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlLink,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import DropdownContentsLabelsView from '~/sidebar/components/labels/labels_select_vue/dropdown_contents_labels_view.vue';
import LabelItem from '~/sidebar/components/labels/labels_select_vue/label_item.vue';
import { stubComponent } from 'helpers/stub_component';
import * as actions from '~/sidebar/components/labels/labels_select_vue/store/actions';
import * as getters from '~/sidebar/components/labels/labels_select_vue/store/getters';
import mutations from '~/sidebar/components/labels/labels_select_vue/store/mutations';
import defaultState from '~/sidebar/components/labels/labels_select_vue/store/state';

import { mockConfig, mockLabels } from './mock_data';

Vue.use(Vuex);

describe('DropdownContentsLabelsView', () => {
  let wrapper;
  let store;

  const focusInputMock = jest.fn();
  const updateSelectedLabelsMock = jest.fn();
  const toggleDropdownContentsMock = jest.fn();

  const createComponent = (initialState = mockConfig, mountFn = shallowMountExtended) => {
    store = new Vuex.Store({
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
        updateSelectedLabels: updateSelectedLabelsMock,
        toggleDropdownContents: toggleDropdownContentsMock,
      },
    });

    store.dispatch('setInitialState', initialState);

    wrapper = mountFn(DropdownContentsLabelsView, {
      store,
      stubs: {
        GlSearchBoxByType: stubComponent(GlSearchBoxByType, {
          methods: { focusInput: focusInputMock },
        }),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findDropdownContent = () => wrapper.findByTestId('dropdown-content');
  const findDropdownTitle = () => wrapper.findByTestId('dropdown-title');
  const findDropdownFooter = () => wrapper.findByTestId('dropdown-footer');
  const findNoMatchingResults = () => wrapper.findByTestId('no-matching-results');
  const findCreateLabelLink = () => wrapper.findByTestId('create-label-link');
  const findLabelsList = () => wrapper.findByTestId('labels-list');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findSearchBoxByType = () => wrapper.findComponent(GlSearchBoxByType);
  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findLabelItems = () => wrapper.findAllComponents(LabelItem);

  const setCurrentHighlightItem = (value) => {
    let initialValue = -1;

    while (initialValue < value) {
      findLabelsList().trigger('keydown.down');
      initialValue += 1;
    }
  };

  describe('component', () => {
    it('calls `focusInput` on searchInput field when the component appears', async () => {
      findIntersectionObserver().vm.$emit('appear');

      await nextTick();

      expect(focusInputMock).toHaveBeenCalled();
    });

    it('removes loaded labels when the component disappears', async () => {
      jest.spyOn(store, 'dispatch');

      await findIntersectionObserver().vm.$emit('disappear');

      expect(store.dispatch).toHaveBeenCalledWith(expect.anything(), []);
    });
  });

  describe('labels', () => {
    describe('when it is visible', () => {
      beforeEach(() => {
        createComponent(undefined, mountExtended);
        store.dispatch('receiveLabelsSuccess', mockLabels);
      });

      it('returns matching labels filtered with `searchKey`', async () => {
        await findSearchBoxByType().vm.$emit('input', 'bug');

        const labelItems = findLabelItems();
        expect(labelItems).toHaveLength(1);
        expect(labelItems.at(0).text()).toBe('Bug');
      });

      it('returns matching labels with fuzzy filtering', async () => {
        await findSearchBoxByType().vm.$emit('input', 'bg');

        const labelItems = findLabelItems();
        expect(labelItems).toHaveLength(2);
        expect(labelItems.at(0).text()).toBe('Bug');
        expect(labelItems.at(1).text()).toBe('Boog');
      });

      it('returns all labels when `searchKey` is empty', async () => {
        await findSearchBoxByType().vm.$emit('input', '');

        expect(findLabelItems()).toHaveLength(mockLabels.length);
      });
    });

    describe('when it is clicked', () => {
      beforeEach(() => {
        createComponent(undefined, mountExtended);
        store.dispatch('receiveLabelsSuccess', mockLabels);
      });

      it('calls action `updateSelectedLabels` with provided `label` param', () => {
        findLabelItems().at(0).findComponent(GlLink).vm.$emit('click');

        expect(updateSelectedLabelsMock).toHaveBeenCalledWith(expect.anything(), [
          { ...mockLabels[0], indeterminate: expect.anything(), set: expect.anything() },
        ]);
      });

      it('calls action `toggleDropdownContents` when `state.allowMultiselect` is false', () => {
        store.state.allowMultiselect = false;

        findLabelItems().at(0).findComponent(GlLink).vm.$emit('click');

        expect(toggleDropdownContentsMock).toHaveBeenCalled();
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
          store.dispatch('receiveLabelsSuccess', labels);

          await findSearchBoxByType().vm.$emit('input', searchKey);

          expect(findNoMatchingResults().isVisible()).toBe(returnValue);
        },
      );
    });
  });

  describe('create label link', () => {
    it('calls actions `receiveLabelsSuccess` with empty array and `toggleDropdownContentsCreateView`', async () => {
      jest.spyOn(store, 'dispatch');

      await findCreateLabelLink().vm.$emit('click');

      expect(store.dispatch).toHaveBeenCalledWith('receiveLabelsSuccess', []);
      expect(store.dispatch).toHaveBeenCalledWith('toggleDropdownContentsCreateView');
    });
  });

  describe('keyboard navigation', () => {
    const fakePreventDefault = jest.fn();

    beforeEach(() => {
      createComponent(undefined, mountExtended);
      store.dispatch('receiveLabelsSuccess', mockLabels);
    });

    describe('when the "down" key is pressed', () => {
      it('highlights the item', async () => {
        expect(findLabelItems().at(0).classes()).not.toContain('is-focused');

        await findLabelsList().trigger('keydown.down');

        expect(findLabelItems().at(0).classes()).toContain('is-focused');
      });
    });

    describe('when the "up" arrow key is pressed', () => {
      it('un-highlights the item', async () => {
        await setCurrentHighlightItem(1);

        expect(findLabelItems().at(1).classes()).toContain('is-focused');

        await findLabelsList().trigger('keydown.up');

        expect(findLabelItems().at(1).classes()).not.toContain('is-focused');
      });
    });

    describe('when the "enter" key is pressed', () => {
      it('resets the search text', async () => {
        await setCurrentHighlightItem(1);
        await findSearchBoxByType().vm.$emit('input', 'bug');
        await findLabelsList().trigger('keydown.enter', { preventDefault: fakePreventDefault });

        expect(findSearchBoxByType().props('value')).toBe('');
        expect(fakePreventDefault).toHaveBeenCalled();
      });

      it('calls action `updateSelectedLabels` with currently highlighted label', async () => {
        await setCurrentHighlightItem(2);
        await findLabelsList().trigger('keydown.enter', { preventDefault: fakePreventDefault });

        expect(updateSelectedLabelsMock).toHaveBeenCalledWith(expect.anything(), [mockLabels[2]]);
      });
    });

    describe('when the "esc" key is pressed', () => {
      it('calls action `toggleDropdownContents`', async () => {
        await setCurrentHighlightItem(1);
        await findLabelsList().trigger('keydown.esc');

        expect(toggleDropdownContentsMock).toHaveBeenCalled();
      });

      it('scrolls dropdown content into view', async () => {
        const containerTop = 500;
        const labelTop = 0;

        jest
          .spyOn(findDropdownContent().element, 'getBoundingClientRect')
          .mockReturnValueOnce({ top: containerTop });

        await setCurrentHighlightItem(1);
        await findLabelsList().trigger('keydown.esc');

        expect(findDropdownContent().element.scrollTop).toBe(labelTop - containerTop);
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      store.dispatch('receiveLabelsSuccess', mockLabels);
    });

    it('renders gl-intersection-observer as component root', () => {
      expect(wrapper.findComponent(GlIntersectionObserver).exists()).toBe(true);
    });

    it('renders gl-loading-icon component when `labelsFetchInProgress` prop is true', async () => {
      store.dispatch('requestLabels');

      await nextTick();
      const loadingIconEl = findLoadingIcon();

      expect(loadingIconEl.exists()).toBe(true);
      expect(loadingIconEl.attributes('class')).toContain('labels-fetch-loading');
    });

    it('renders dropdown title element', () => {
      const titleEl = findDropdownTitle();

      expect(titleEl.exists()).toBe(true);
      expect(titleEl.text()).toBe('Select labels');
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
      const closeButtonEl = findDropdownTitle().findComponent(GlButton);

      expect(closeButtonEl.exists()).toBe(true);
      expect(closeButtonEl.props('icon')).toBe('close');
    });

    it('renders label search input element', () => {
      const searchInputEl = wrapper.findComponent(GlSearchBoxByType);

      expect(searchInputEl.exists()).toBe(true);
    });

    it('renders label elements for all labels', () => {
      expect(findLabelItems()).toHaveLength(mockLabels.length);
    });

    it('renders label element with `highlight` set to true when value of `currentHighlightItem` is more than -1', async () => {
      await setCurrentHighlightItem(0);

      const labelItemEl = findDropdownContent().findComponent(LabelItem);

      expect(labelItemEl.attributes('highlight')).toBe('true');
    });

    it('renders element containing "No matching results" when `searchKey` does not match with any label', async () => {
      await findSearchBoxByType().vm.$emit('input', 'abc');
      const noMatchEl = findDropdownContent().find('li');

      expect(noMatchEl.isVisible()).toBe(true);
      expect(noMatchEl.text()).toContain('No matching results');
    });

    it('renders empty content while loading', async () => {
      store.state.labelsFetchInProgress = true;

      await nextTick();
      const dropdownContent = findDropdownContent();
      const loadingIcon = findLoadingIcon();

      expect(dropdownContent.exists()).toBe(true);
      expect(dropdownContent.isVisible()).toBe(true);
      expect(loadingIcon.exists()).toBe(true);
      expect(loadingIcon.isVisible()).toBe(true);
    });

    it('renders footer list items', () => {
      const footerLinks = findDropdownFooter().findAllComponents(GlLink);
      const createLabelLink = footerLinks.at(0);
      const manageLabelsLink = footerLinks.at(1);

      expect(createLabelLink.exists()).toBe(true);
      expect(createLabelLink.text()).toBe('Create label');
      expect(manageLabelsLink.exists()).toBe(true);
      expect(manageLabelsLink.text()).toBe('Manage labels');
    });

    it('does not render "Create label" footer link when `state.allowLabelCreate` is `false`', async () => {
      store.state.allowLabelCreate = false;

      await nextTick();
      const createLabelLink = findDropdownFooter().findAllComponents(GlLink).at(0);

      expect(createLabelLink.text()).not.toBe('Create label');
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
