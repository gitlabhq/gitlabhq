import { nextTick } from 'vue';
import { GlFormInputGroup } from '@gitlab/ui';

import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { MOUSETRAP_COPY_KEYBOARD_SHORTCUT } from '~/lib/mousetrap';

describe('InputCopyToggleVisibility', () => {
  let wrapper;

  const valueProp = 'hR8x1fuJbzwu5uFKLf9e';

  const createComponent = ({ props, ...options } = {}) => {
    wrapper = mountExtended(InputCopyToggleVisibility, {
      propsData: props,
      ...options,
    });
  };

  const findFormInputGroup = () => wrapper.findComponent(GlFormInputGroup);
  const findFormInput = () => findFormInputGroup().find('input');
  const findRevealButton = () =>
    wrapper.findByRole('button', {
      name: InputCopyToggleVisibility.i18n.toggleVisibilityLabelReveal,
    });
  const findHideButton = () =>
    wrapper.findByRole('button', {
      name: InputCopyToggleVisibility.i18n.toggleVisibilityLabelHide,
    });
  const findCopyButton = () => wrapper.findComponent(ClipboardButton);
  const createCopyEvent = () => {
    const event = new Event('copy', { cancelable: true });
    Object.assign(event, { preventDefault: jest.fn(), clipboardData: { setData: jest.fn() } });

    return event;
  };
  const triggerCopyShortcut = () => {
    wrapper.vm.mousetrap.trigger(MOUSETRAP_COPY_KEYBOARD_SHORTCUT);
  };

  function expectInputToBeMasked() {
    expect(findFormInput().classes()).toContain('input-copy-show-disc');
  }

  function expectInputToBeRevealed() {
    expect(findFormInput().classes()).not.toContain('input-copy-show-disc');
    expect(findFormInput().element.value).toBe(valueProp);
  }

  const itDoesNotModifyCopyEvent = () => {
    it('does not modify copy event', () => {
      const event = createCopyEvent();

      findFormInput().element.dispatchEvent(event);

      expect(event.clipboardData.setData).not.toHaveBeenCalled();
      expect(event.preventDefault).not.toHaveBeenCalled();
    });
  };

  describe('when `value` prop is passed', () => {
    beforeEach(() => {
      createComponent({
        props: {
          value: valueProp,
        },
      });
    });

    it('hides the value with a password input', () => {
      expectInputToBeMasked();
    });

    it('emits `copy` event and sets clipboard when copying token via keyboard shortcut', async () => {
      const writeTextSpy = jest.spyOn(global.navigator.clipboard, 'writeText');

      expect(wrapper.emitted('copy')).toBeUndefined();

      triggerCopyShortcut();
      await nextTick();

      expect(wrapper.emitted('copy')[0]).toEqual([]);
      expect(writeTextSpy).toHaveBeenCalledWith(valueProp);
    });

    describe('copy button', () => {
      it('renders button with correct props passed', () => {
        expect(findCopyButton().props()).toMatchObject({
          text: valueProp,
          title: 'Copy',
        });
      });

      describe('when clicked', () => {
        beforeEach(async () => {
          await findCopyButton().trigger('click');
        });

        it('emits `copy` event', () => {
          expect(wrapper.emitted()).toHaveProperty('copy');
          expect(wrapper.emitted('copy')).toHaveLength(1);
          expect(wrapper.emitted('copy')[0]).toEqual([]);
        });
      });
    });
  });

  describe('when input is readonly', () => {
    describe('visibility toggle button', () => {
      beforeEach(() => {
        createComponent({
          props: {
            value: valueProp,
            readonly: true,
          },
          directives: {
            GlTooltip: createMockDirective('gl-tooltip'),
          },
        });
      });

      it('renders a reveal button', () => {
        const revealButton = findRevealButton();

        expect(revealButton.exists()).toBe(true);

        const tooltip = getBinding(revealButton.element, 'gl-tooltip');

        expect(tooltip.value).toBe(InputCopyToggleVisibility.i18n.toggleVisibilityLabelReveal);
      });

      describe('when clicked', () => {
        let event;

        beforeEach(async () => {
          event = { stopPropagation: jest.fn() };
          await findRevealButton().trigger('click', event);
        });

        it('displays value', () => {
          expectInputToBeRevealed();
        });

        it('renders a hide button', () => {
          const hideButton = findHideButton();

          expect(hideButton.exists()).toBe(true);

          const tooltip = getBinding(hideButton.element, 'gl-tooltip');

          expect(tooltip.value).toBe(InputCopyToggleVisibility.i18n.toggleVisibilityLabelHide);
        });

        it('emits `visibility-change` event', () => {
          expect(wrapper.emitted('visibility-change')[0]).toEqual([true]);
        });

        it('stops propagation on click event', () => {
          // in case the input is located in a dropdown or modal
          expect(event.stopPropagation).toHaveBeenCalledTimes(1);
        });
      });
    });

    describe('when `initialVisibility` prop is `true`', () => {
      const label = 'My label';
      beforeEach(() => {
        createComponent({
          props: {
            value: valueProp,
            initialVisibility: true,
            readonly: true,
            label,
            'label-for': 'my-input',
            formInputGroupProps: {
              id: 'my-input',
            },
          },
        });
      });

      it('displays value', () => {
        expectInputToBeRevealed();
      });

      itDoesNotModifyCopyEvent();

      describe('when input is clicked', () => {
        it('selects input value', async () => {
          const mockSelect = jest.fn();
          findFormInput().element.select = mockSelect;
          await findFormInput().trigger('click');

          expect(mockSelect).toHaveBeenCalled();
        });
      });

      describe('when label is clicked', () => {
        it('selects input value', async () => {
          const mockSelect = jest.fn();
          findFormInput().element.select = mockSelect;
          await wrapper.find('label').trigger('click');

          expect(mockSelect).toHaveBeenCalled();
        });
      });
    });
  });

  describe('when input is editable', () => {
    describe('and no `value` prop is passed', () => {
      beforeEach(() => {
        createComponent({
          props: {
            value: '',
            readonly: false,
          },
        });
      });

      it('displays value', () => {
        expect(findRevealButton().exists()).toBe(false);
        expect(findHideButton().exists()).toBe(true);

        const input = findFormInput();
        input.element.value = valueProp;
        input.trigger('input');

        expectInputToBeRevealed();
      });
    });

    describe('and `value` prop is passed', () => {
      describe('tooltip', () => {
        beforeEach(() => {
          createComponent({
            props: {
              value: valueProp,
              readonly: false,
            },
            directives: {
              GlTooltip: createMockDirective('gl-tooltip'),
            },
          });
        });

        it('renders a reveal button', () => {
          const revealButton = findRevealButton();

          expect(revealButton.exists()).toBe(true);

          const tooltip = getBinding(revealButton.element, 'gl-tooltip');

          expect(tooltip.value).toBe(InputCopyToggleVisibility.i18n.toggleVisibilityLabelReveal);
        });

        it('renders a hide button once revealed', async () => {
          const revealButton = findRevealButton();
          await revealButton.trigger('click');
          await nextTick();

          const hideButton = findHideButton();
          expect(hideButton.exists()).toBe(true);

          const tooltip = getBinding(hideButton.element, 'gl-tooltip');

          expect(tooltip.value).toBe(InputCopyToggleVisibility.i18n.toggleVisibilityLabelHide);
        });
      });

      describe('no tooltip', () => {
        beforeEach(() => {
          createComponent({
            props: {
              value: valueProp,
              readonly: false,
            },
          });
        });

        it('emits `input` event when editing', () => {
          expect(wrapper.emitted('input')).toBeUndefined();
          const newVal = 'ding!';

          const input = findFormInput();
          input.element.value = newVal;
          input.trigger('input');

          expect(wrapper.emitted()).toHaveProperty('input');
          expect(wrapper.emitted('input')).toHaveLength(1);
          expect(wrapper.emitted('input')[0][0]).toBe(newVal);
        });

        it('copies updated value to clipboard after editing', async () => {
          const writeTextSpy = jest.spyOn(global.navigator.clipboard, 'writeText');

          triggerCopyShortcut();
          await nextTick();

          expect(wrapper.emitted('copy')).toHaveLength(1);
          expect(writeTextSpy).toHaveBeenCalledWith(valueProp);

          const updatedValue = 'wow amazing';
          wrapper.setProps({ value: updatedValue });
          await nextTick();

          triggerCopyShortcut();
          await nextTick();

          expect(wrapper.emitted('copy')).toHaveLength(2);
          expect(writeTextSpy).toHaveBeenCalledWith(updatedValue);
        });

        describe('when input is clicked', () => {
          it('shows the actual value', async () => {
            const input = findFormInput();

            expectInputToBeMasked();
            await findFormInput().trigger('click');

            expect(input.element.value).toBe(valueProp);
          });

          it('ensures the selection start/end are in the correct position once the actual value has been revealed', async () => {
            const input = findFormInput();
            const selectionStart = 2;
            const selectionEnd = 4;

            input.element.setSelectionRange(selectionStart, selectionEnd);
            await input.trigger('click');

            expect(input.element.selectionStart).toBe(selectionStart);
            expect(input.element.selectionEnd).toBe(selectionEnd);
          });
        });
      });
    });

    describe('and the input is invalid', () => {
      beforeEach(() => {
        createComponent({
          props: {
            value: '',
            readonly: false,
            formInputGroupProps: { state: false },
          },
          attrs: {
            'invalid-feedback': 'Oh no, something is invalid',
          },
        });
      });

      it('should add class to force validation message visibility', () => {
        expect(wrapper.classes('input-copy-toggle-visibility-is-invalid')).toBe(true);
      });
    });
  });

  describe('when `showToggleVisibilityButton` is `false`', () => {
    beforeEach(() => {
      createComponent({
        props: {
          value: valueProp,
          showToggleVisibilityButton: false,
        },
      });
    });

    it('does not render visibility toggle button', () => {
      expect(findRevealButton().exists()).toBe(false);
      expect(findHideButton().exists()).toBe(false);
    });

    it('displays value', () => {
      expectInputToBeRevealed();
    });

    itDoesNotModifyCopyEvent();
  });

  describe('when `showCopyButton` is `false`', () => {
    beforeEach(() => {
      createComponent({
        props: {
          showCopyButton: false,
        },
      });
    });

    it('does not render copy button', () => {
      expect(findCopyButton().exists()).toBe(false);
    });
  });

  describe('when `size` is used', () => {
    it('passes no `size` prop', () => {
      createComponent();

      expect(findFormInput().props('width')).toBe(null);
    });

    it('passes `size` prop to the input', () => {
      createComponent({ props: { size: 'md' } });

      expect(findFormInput().props('width')).toBe('md');
    });
  });

  it('passes `formInputGroupProps` prop only to the input', () => {
    createComponent({
      props: {
        formInputGroupProps: {
          name: 'Foo bar',
          'data-testid': 'Foo bar',
          class: 'Foo bar',
          id: 'Foo bar',
        },
      },
    });

    expect(findFormInput().attributes()).toMatchObject({
      name: 'Foo bar',
      'data-testid': 'Foo bar',
      class: expect.stringContaining('Foo bar'),
      id: 'Foo bar',
    });

    const attributesInputGroup = findFormInputGroup().attributes();
    expect(attributesInputGroup.name).toBeUndefined();
    expect(attributesInputGroup['data-testid']).toBeUndefined();
    expect(attributesInputGroup.class).not.toContain('Foo bar');
    expect(attributesInputGroup.id).toBeUndefined();
  });

  it('passes `copyButtonTitle` prop to `ClipboardButton`', () => {
    createComponent({
      props: {
        copyButtonTitle: 'Copy token',
      },
    });

    expect(findCopyButton().props('title')).toBe('Copy token');
  });

  it('renders slots in `gl-form-group`', () => {
    const description = 'Mock input description';
    createComponent({
      slots: {
        description,
      },
    });

    expect(wrapper.findByText(description).exists()).toBe(true);
  });
});
