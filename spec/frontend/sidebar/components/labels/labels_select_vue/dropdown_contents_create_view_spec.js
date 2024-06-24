import { GlButton, GlFormInput, GlLink, GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import DropdownContentsCreateView from '~/sidebar/components/labels/labels_select_vue/dropdown_contents_create_view.vue';

import labelSelectModule from '~/sidebar/components/labels/labels_select_vue/store';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { mockConfig, mockSuggestedColors } from './mock_data';

Vue.use(Vuex);

describe('DropdownContentsCreateView', () => {
  let wrapper;
  let store;

  const colors = Object.keys(mockSuggestedColors).map((color) => ({
    [color]: mockSuggestedColors[color],
  }));

  const createComponent = (initialState = mockConfig) => {
    store = new Vuex.Store(labelSelectModule());
    store.dispatch('setInitialState', initialState);

    wrapper = shallowMountExtended(DropdownContentsCreateView, {
      store,
    });
  };

  const findColorSelectorInput = () => wrapper.findByTestId('selected-color');
  const findLabelTitleInput = () => wrapper.findByTestId('label-title');
  const findCreateClickButton = () => wrapper.findByTestId('create-click');
  const findAllLinks = () => wrapper.find('.dropdown-content').findAllComponents(GlLink);

  beforeEach(() => {
    gon.suggested_label_colors = mockSuggestedColors;
    createComponent();
  });

  describe('computed', () => {
    describe('disableCreate', () => {
      it('returns `true` when label title and color is not defined', () => {
        expect(findCreateClickButton().props('disabled')).toBe(true);
      });

      it('returns `true` when `labelCreateInProgress` is true', async () => {
        await findColorSelectorInput().vm.$emit('input', '#ff0000');
        await findLabelTitleInput().vm.$emit('input', 'Foo');
        store.dispatch('requestCreateLabel');

        await nextTick();

        expect(findCreateClickButton().props('disabled')).toBe(true);
      });

      it('returns `false` when label title and color is defined and create request is not already in progress', async () => {
        await findColorSelectorInput().vm.$emit('input', '#ff0000');
        await findLabelTitleInput().vm.$emit('input', 'Foo');

        expect(findCreateClickButton().props('disabled')).toBe(false);
      });
    });

    describe('suggestedColors', () => {
      it('returns array of color objects containing color code and name', () => {
        colors.forEach((color, index) => {
          expect(findAllLinks().at(index).attributes('title')).toBe(Object.values(color)[0]);
        });
      });
    });
  });

  describe('methods', () => {
    describe('getColorCode', () => {
      it('returns color code from color object', () => {
        expect(wrapper.vm.getColorCode(colors[0])).toBe(Object.keys(colors[0]).pop());
      });
    });

    describe('getColorName', () => {
      it('returns color name from color object', () => {
        expect(findAllLinks().at(0).attributes('title')).toBe(Object.values(colors[0]).pop());
      });
    });

    describe('handleColorClick', () => {
      it('sets provided `color` param to `selectedColor` prop', async () => {
        await findAllLinks()
          .at(0)
          .vm.$emit('click', { preventDefault: () => {} });

        expect(findColorSelectorInput().attributes('value')).toBe(Object.keys(colors[0]).pop());
      });
    });

    describe('handleCreateClick', () => {
      it('calls action `createLabel` with object containing `labelTitle` & `selectedColor`', async () => {
        jest.spyOn(store, 'dispatch').mockImplementation();
        await findColorSelectorInput().vm.$emit('input', '#ff0000');
        await findLabelTitleInput().vm.$emit('input', 'Foo');

        findCreateClickButton().vm.$emit('click');

        await nextTick();
        expect(store.dispatch).toHaveBeenCalledWith('createLabel', {
          title: 'Foo',
          color: '#ff0000',
        });
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class "labels-select-contents-create"', () => {
      expect(wrapper.attributes('class')).toContain('labels-select-contents-create');
    });

    it('renders dropdown back button element', () => {
      const backBtnEl = wrapper.find('.dropdown-title').findAllComponents(GlButton).at(0);

      expect(backBtnEl.exists()).toBe(true);
      expect(backBtnEl.attributes('aria-label')).toBe('Go back');
      expect(backBtnEl.props('icon')).toBe('arrow-left');
    });

    it('renders dropdown title element', () => {
      const headerEl = wrapper.find('.dropdown-title > span');

      expect(headerEl.exists()).toBe(true);
      expect(headerEl.text()).toBe('Create label');
    });

    it('renders dropdown close button element', () => {
      const closeBtnEl = wrapper.find('.dropdown-title').findAllComponents(GlButton).at(1);

      expect(closeBtnEl.exists()).toBe(true);
      expect(closeBtnEl.attributes('aria-label')).toBe('Close');
      expect(closeBtnEl.props('icon')).toBe('close');
    });

    it('renders label title input element', () => {
      const titleInputEl = wrapper.find('.dropdown-input').findComponent(GlFormInput);

      expect(titleInputEl.exists()).toBe(true);
      expect(titleInputEl.attributes('placeholder')).toBe('Label name');
      expect(titleInputEl.attributes('autofocus')).toBe('true');
    });

    it('renders color block element for all suggested colors', () => {
      findAllLinks().wrappers.forEach((colorBlock, index) => {
        expect(colorBlock.attributes('style')).toContain('background-color');
        expect(colorBlock.attributes('title')).toBe(Object.values(colors[index]).pop());
      });
    });

    it('renders color input element', async () => {
      await findColorSelectorInput().vm.$emit('input', '#ff0000');

      await nextTick();
      const colorPreviewEl = wrapper
        .find('.color-input-container')
        .findAllComponents(GlFormInput)
        .at(0);
      const colorInputEl = wrapper
        .find('.color-input-container')
        .findAllComponents(GlFormInput)
        .at(1);

      expect(colorPreviewEl.exists()).toBe(true);
      expect(colorPreviewEl.attributes('value')).toBe('#ff0000');
      expect(colorInputEl.exists()).toBe(true);
      expect(colorInputEl.attributes('placeholder')).toBe('Use custom color #FF0000');
      expect(colorInputEl.attributes('value')).toBe('#ff0000');
    });

    it('renders create button element', () => {
      const createBtnEl = wrapper.find('.dropdown-actions').findAllComponents(GlButton).at(0);

      expect(createBtnEl.exists()).toBe(true);
      expect(createBtnEl.text()).toContain('Create');
    });

    it('shows gl-loading-icon within create button element when `labelCreateInProgress` is `true`', async () => {
      store.dispatch('requestCreateLabel');

      await nextTick();
      const loadingIconEl = wrapper.find('.dropdown-actions').findComponent(GlLoadingIcon);

      expect(loadingIconEl.exists()).toBe(true);
      expect(loadingIconEl.isVisible()).toBe(true);
    });

    it('renders cancel button element', () => {
      const cancelBtnEl = wrapper.find('.dropdown-actions').findAllComponents(GlButton).at(1);

      expect(cancelBtnEl.exists()).toBe(true);
      expect(cancelBtnEl.text()).toContain('Cancel');
    });
  });
});
