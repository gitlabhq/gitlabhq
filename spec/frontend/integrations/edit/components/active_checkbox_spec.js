import { mount } from '@vue/test-utils';
import { GlFormCheckbox } from '@gitlab/ui';
import { createStore } from '~/integrations/edit/store';

import ActiveCheckbox from '~/integrations/edit/components/active_checkbox.vue';

describe('ActiveCheckbox', () => {
  let wrapper;

  const createComponent = (customStateProps = {}, isInheriting = false) => {
    wrapper = mount(ActiveCheckbox, {
      store: createStore({
        customState: { ...customStateProps },
      }),
      computed: {
        isInheriting: () => isInheriting,
      },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findGlFormCheckbox = () => wrapper.find(GlFormCheckbox);
  const findInputInCheckbox = () => findGlFormCheckbox().find('input');

  describe('template', () => {
    describe('is inheriting adminSettings', () => {
      it('renders GlFormCheckbox as disabled', () => {
        createComponent({}, true);

        expect(findGlFormCheckbox().exists()).toBe(true);
        expect(findInputInCheckbox().attributes('disabled')).toBe('disabled');
      });
    });

    describe('initialActivated is false', () => {
      it('renders GlFormCheckbox as unchecked', () => {
        createComponent({
          initialActivated: false,
        });

        expect(findGlFormCheckbox().exists()).toBe(true);
        expect(findGlFormCheckbox().vm.$attrs.checked).toBe(false);
        expect(findInputInCheckbox().attributes('disabled')).toBeUndefined();
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

      describe('on checkbox click', () => {
        it('switches the form value', async () => {
          findInputInCheckbox().trigger('click');

          await wrapper.vm.$nextTick();

          expect(findGlFormCheckbox().vm.$attrs.checked).toBe(false);
        });
      });
    });
  });
});
