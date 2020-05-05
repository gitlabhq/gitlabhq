import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import { GlButton, GlFormInput, GlLink, GlLoadingIcon } from '@gitlab/ui';
import DropdownContentsCreateView from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_contents_create_view.vue';

import labelSelectModule from '~/vue_shared/components/sidebar/labels_select_vue/store';

import { mockConfig, mockSuggestedColors } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = (initialState = mockConfig) => {
  const store = new Vuex.Store(labelSelectModule());

  store.dispatch('setInitialState', initialState);

  return shallowMount(DropdownContentsCreateView, {
    localVue,
    store,
  });
};

describe('DropdownContentsCreateView', () => {
  let wrapper;
  const colors = Object.keys(mockSuggestedColors).map(color => ({
    [color]: mockSuggestedColors[color],
  }));

  beforeEach(() => {
    gon.suggested_label_colors = mockSuggestedColors;
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('disableCreate', () => {
      it('returns `true` when label title and color is not defined', () => {
        expect(wrapper.vm.disableCreate).toBe(true);
      });

      it('returns `true` when `labelCreateInProgress` is true', () => {
        wrapper.setData({
          labelTitle: 'Foo',
          selectedColor: '#ff0000',
        });
        wrapper.vm.$store.dispatch('requestCreateLabel');

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.disableCreate).toBe(true);
        });
      });

      it('returns `false` when label title and color is defined and create request is not already in progress', () => {
        wrapper.setData({
          labelTitle: 'Foo',
          selectedColor: '#ff0000',
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.disableCreate).toBe(false);
        });
      });
    });

    describe('suggestedColors', () => {
      it('returns array of color objects containing color code and name', () => {
        colors.forEach((color, index) => {
          expect(wrapper.vm.suggestedColors[index]).toEqual(expect.objectContaining(color));
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
        expect(wrapper.vm.getColorName(colors[0])).toBe(Object.values(colors[0]).pop());
      });
    });

    describe('handleColorClick', () => {
      it('sets provided `color` param to `selectedColor` prop', () => {
        wrapper.vm.handleColorClick(colors[0]);

        expect(wrapper.vm.selectedColor).toBe(Object.keys(colors[0]).pop());
      });
    });

    describe('handleCreateClick', () => {
      it('calls action `createLabel` with object containing `labelTitle` & `selectedColor`', () => {
        jest.spyOn(wrapper.vm, 'createLabel').mockImplementation();
        wrapper.setData({
          labelTitle: 'Foo',
          selectedColor: '#ff0000',
        });

        wrapper.vm.handleCreateClick();

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.createLabel).toHaveBeenCalledWith(
            expect.objectContaining({
              title: 'Foo',
              color: '#ff0000',
            }),
          );
        });
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class "labels-select-contents-create"', () => {
      expect(wrapper.attributes('class')).toContain('labels-select-contents-create');
    });

    it('renders dropdown back button element', () => {
      const backBtnEl = wrapper
        .find('.dropdown-title')
        .findAll(GlButton)
        .at(0);

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
      const closeBtnEl = wrapper
        .find('.dropdown-title')
        .findAll(GlButton)
        .at(1);

      expect(closeBtnEl.exists()).toBe(true);
      expect(closeBtnEl.attributes('aria-label')).toBe('Close');
      expect(closeBtnEl.props('icon')).toBe('close');
    });

    it('renders label title input element', () => {
      const titleInputEl = wrapper.find('.dropdown-input').find(GlFormInput);

      expect(titleInputEl.exists()).toBe(true);
      expect(titleInputEl.attributes('placeholder')).toBe('Name new label');
      expect(titleInputEl.attributes('autofocus')).toBe('true');
    });

    it('renders color block element for all suggested colors', () => {
      const colorBlocksEl = wrapper.find('.dropdown-content').findAll(GlLink);

      colorBlocksEl.wrappers.forEach((colorBlock, index) => {
        expect(colorBlock.attributes('style')).toContain('background-color');
        expect(colorBlock.attributes('title')).toBe(Object.values(colors[index]).pop());
      });
    });

    it('renders color input element', () => {
      wrapper.setData({
        selectedColor: '#ff0000',
      });

      return wrapper.vm.$nextTick(() => {
        const colorPreviewEl = wrapper.find(
          '.color-input-container > .dropdown-label-color-preview',
        );
        const colorInputEl = wrapper.find('.color-input-container').find(GlFormInput);

        expect(colorPreviewEl.exists()).toBe(true);
        expect(colorPreviewEl.attributes('style')).toContain('background-color');
        expect(colorInputEl.exists()).toBe(true);
        expect(colorInputEl.attributes('placeholder')).toBe('Use custom color #FF0000');
        expect(colorInputEl.attributes('value')).toBe('#ff0000');
      });
    });

    it('renders create button element', () => {
      const createBtnEl = wrapper
        .find('.dropdown-actions')
        .findAll(GlButton)
        .at(0);

      expect(createBtnEl.exists()).toBe(true);
      expect(createBtnEl.text()).toContain('Create');
    });

    it('shows gl-loading-icon within create button element when `labelCreateInProgress` is `true`', () => {
      wrapper.vm.$store.dispatch('requestCreateLabel');

      return wrapper.vm.$nextTick(() => {
        const loadingIconEl = wrapper.find('.dropdown-actions').find(GlLoadingIcon);

        expect(loadingIconEl.exists()).toBe(true);
        expect(loadingIconEl.isVisible()).toBe(true);
      });
    });

    it('renders cancel button element', () => {
      const cancelBtnEl = wrapper
        .find('.dropdown-actions')
        .findAll(GlButton)
        .at(1);

      expect(cancelBtnEl.exists()).toBe(true);
      expect(cancelBtnEl.text()).toContain('Cancel');
    });
  });
});
