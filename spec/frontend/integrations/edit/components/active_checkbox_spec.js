import { GlFormCheckbox } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import ActiveCheckbox from '~/integrations/edit/components/active_checkbox.vue';
import { createStore } from '~/integrations/edit/store';

describe('ActiveCheckbox', () => {
  let wrapper;

  const createComponent = (customStateProps = {}, { isInheriting = false } = {}) => {
    wrapper = mount(ActiveCheckbox, {
      store: createStore({
        customState: { ...customStateProps },
        override: !isInheriting,
        defaultState: isInheriting ? {} : undefined,
      }),
    });
  };

  const findGlFormCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findInputInCheckbox = () => findGlFormCheckbox().find('input');

  describe('template', () => {
    describe('is inheriting adminSettings', () => {
      it('renders GlFormCheckbox as disabled', () => {
        createComponent({}, { isInheriting: true });

        expect(findGlFormCheckbox().exists()).toBe(true);
        expect(findInputInCheckbox().attributes('disabled')).toBeDefined();
      });
    });

    describe('when activateDisabled is true', () => {
      it('renders GlFormCheckbox as disabled', () => {
        createComponent({ activateDisabled: true });

        expect(findGlFormCheckbox().exists()).toBe(true);
        expect(findInputInCheckbox().attributes('disabled')).toBeDefined();
      });
    });

    describe('initialActivated is `false`', () => {
      beforeEach(() => {
        createComponent({
          initialActivated: false,
        });
      });

      it('renders GlFormCheckbox as unchecked', () => {
        expect(findGlFormCheckbox().exists()).toBe(true);
        expect(findGlFormCheckbox().vm.$attrs.checked).toBe(false);
        expect(findInputInCheckbox().attributes('disabled')).toBeUndefined();
      });

      it('emits `toggle-integration-active` event with `false` on mount', () => {
        expect(wrapper.emitted('toggle-integration-active')[0]).toEqual([false]);
      });
    });

    describe('initialActivated is true', () => {
      beforeEach(() => {
        createComponent({
          initialActivated: true,
        });
      });

      it('renders GlFormCheckbox as checked', () => {
        expect(findGlFormCheckbox().exists()).toBe(true);
        expect(findGlFormCheckbox().vm.$attrs.checked).toBe(true);
      });

      it('emits `toggle-integration-active` event with `true` on mount', () => {
        expect(wrapper.emitted('toggle-integration-active')[0]).toEqual([true]);
      });

      describe('on checkbox `change` event', () => {
        it('emits `toggle-integration-active` event', async () => {
          await findInputInCheckbox().setChecked(false);

          expect(wrapper.emitted('toggle-integration-active')[1]).toEqual([false]);
        });
      });
    });
  });
});
