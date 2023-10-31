import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NewMergeRequestOption from '~/ide/components/commit_sidebar/new_merge_request_option.vue';
import { createStoreOptions } from '~/ide/stores';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

Vue.use(Vuex);

describe('NewMergeRequestOption component', () => {
  let store;
  let wrapper;

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findFieldset = () => wrapper.findByTestId('new-merge-request-fieldset');
  const findTooltip = () => getBinding(findFieldset().element, 'gl-tooltip');

  const createComponent = ({
    shouldHideNewMrOption = false,
    shouldDisableNewMrOption = false,
    shouldCreateMR = false,
  } = {}) => {
    const storeOptions = createStoreOptions();

    store = new Vuex.Store({
      ...storeOptions,
      modules: {
        ...storeOptions.modules,
        commit: {
          ...storeOptions.modules.commit,
          getters: {
            shouldHideNewMrOption: () => shouldHideNewMrOption,
            shouldDisableNewMrOption: () => shouldDisableNewMrOption,
            shouldCreateMR: () => shouldCreateMR,
          },
        },
      },
    });

    wrapper = shallowMountExtended(NewMergeRequestOption, {
      store,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  describe('when the `shouldHideNewMrOption` getter returns false', () => {
    beforeEach(() => {
      createComponent();
      jest.spyOn(store, 'dispatch').mockImplementation();
    });

    it('renders an enabled new MR checkbox', () => {
      expect(findCheckbox().attributes('disabled')).toBeUndefined();
    });

    it("doesn't add `is-disabled` class to the fieldset", () => {
      expect(findFieldset().classes()).not.toContain('is-disabled');
    });

    it('dispatches toggleShouldCreateMR when clicking checkbox', () => {
      findCheckbox().vm.$emit('change');

      expect(store.dispatch).toHaveBeenCalledWith('commit/toggleShouldCreateMR', undefined);
    });

    describe('when user cannot create an MR', () => {
      beforeEach(() => {
        createComponent({
          shouldDisableNewMrOption: true,
        });
      });

      it('disables the new MR checkbox', () => {
        expect(findCheckbox().attributes('disabled')).toBeDefined();
      });

      it('adds `is-disabled` class to the fieldset', () => {
        expect(findFieldset().classes()).toContain('is-disabled');
      });

      it('shows a tooltip', () => {
        expect(findTooltip().value).toBe(wrapper.vm.$options.i18n.tooltipText);
      });
    });
  });

  describe('when the `shouldHideNewMrOption` getter returns true', () => {
    beforeEach(() => {
      createComponent({
        shouldHideNewMrOption: true,
      });
    });

    it("doesn't render the new MR checkbox", () => {
      expect(findCheckbox().exists()).toBe(false);
    });
  });
});
