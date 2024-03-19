import { GlFormCheckbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import ActiveCheckbox from '~/integrations/edit/components/active_checkbox.vue';
import { createStore } from '~/integrations/edit/store';

describe('ActiveCheckbox', () => {
  let wrapper;

  const createComponent = ({ customStateProps = {}, isInheriting = false } = {}) => {
    wrapper = shallowMount(ActiveCheckbox, {
      store: createStore({
        customState: { ...customStateProps },
        override: !isInheriting,
        defaultState: isInheriting ? {} : undefined,
      }),
      stubs: {
        GlFormCheckbox,
      },
    });
  };

  const findGlFormCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  describe('template', () => {
    describe('is inheriting adminSettings', () => {
      it('renders GlFormCheckbox as disabled', () => {
        createComponent({ isInheriting: true });

        expect(findGlFormCheckbox().exists()).toBe(true);
        expect(findGlFormCheckbox().attributes().disabled).toBe('true');
      });
    });

    describe('when activateDisabled is true', () => {
      it('renders GlFormCheckbox as disabled', () => {
        createComponent({ customStateProps: { activateDisabled: true } });

        expect(findGlFormCheckbox().exists()).toBe(true);
        expect(findGlFormCheckbox().attributes().disabled).toBe('true');
      });
    });

    describe('initialActivated is `false`', () => {
      beforeEach(() => {
        createComponent({
          customStateProps: {
            initialActivated: false,
          },
        });
      });

      it('renders GlFormCheckbox as unchecked', () => {
        expect(findGlFormCheckbox().exists()).toBe(true);
        expect(findGlFormCheckbox().attributes().checked).toBeUndefined();
        expect(findGlFormCheckbox().attributes().disabled).toBeUndefined();
      });

      it('emits `toggle-integration-active` event with `false` on mount', () => {
        expect(wrapper.emitted('toggle-integration-active')[0]).toEqual([false]);
      });
    });

    describe('initialActivated is true', () => {
      beforeEach(() => {
        createComponent({
          customStateProps: {
            initialActivated: true,
          },
        });
      });

      it('renders GlFormCheckbox as checked', () => {
        expect(findGlFormCheckbox().exists()).toBe(true);
        expect(findGlFormCheckbox().attributes().checked).toBeDefined();
      });

      it('emits `toggle-integration-active` event with `true` on mount', () => {
        expect(wrapper.emitted('toggle-integration-active')[0]).toEqual([true]);
      });

      describe('on checkbox `change` event', () => {
        it('emits `toggle-integration-active` event', () => {
          findGlFormCheckbox().vm.$emit('change', false);

          expect(wrapper.emitted('toggle-integration-active')[1]).toEqual([false]);
        });
      });
    });
  });
});
