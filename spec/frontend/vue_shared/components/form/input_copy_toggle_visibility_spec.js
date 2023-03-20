import { merge } from 'lodash';
import { GlFormInputGroup } from '@gitlab/ui';

import InputCopyToggleVisibility from '~/vue_shared/components/form/input_copy_toggle_visibility.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('InputCopyToggleVisibility', () => {
  let wrapper;

  const valueProp = 'hR8x1fuJbzwu5uFKLf9e';

  const createComponent = (options = {}) => {
    wrapper = mountExtended(
      InputCopyToggleVisibility,
      merge({}, options, {
        directives: {
          GlTooltip: createMockDirective('gl-tooltip'),
        },
      }),
    );
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
        propsData: {
          value: valueProp,
        },
      });
    });

    it('displays value as hidden', () => {
      expect(findFormInput().element.value).toBe('********************');
    });

    it('saves actual value to clipboard when manually copied', () => {
      const event = createCopyEvent();
      findFormInput().element.dispatchEvent(event);

      expect(event.clipboardData.setData).toHaveBeenCalledWith('text/plain', valueProp);
      expect(event.preventDefault).toHaveBeenCalled();
    });

    it('emits `copy` event when manually copied the token', () => {
      expect(wrapper.emitted('copy')).toBeUndefined();

      findFormInput().element.dispatchEvent(createCopyEvent());

      expect(wrapper.emitted()).toHaveProperty('copy');
      expect(wrapper.emitted('copy')).toHaveLength(1);
      expect(wrapper.emitted('copy')[0]).toEqual([]);
    });

    describe('visibility toggle button', () => {
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
          expect(findFormInput().element.value).toBe(valueProp);
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

  describe('when `value` prop is not passed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays value as hidden with 20 asterisks', () => {
      expect(findFormInput().element.value).toBe('********************');
    });
  });

  describe('when `initialVisibility` prop is `true`', () => {
    const label = 'My label';

    beforeEach(() => {
      createComponent({
        propsData: {
          value: valueProp,
          initialVisibility: true,
          label,
          'label-for': 'my-input',
          formInputGroupProps: {
            id: 'my-input',
          },
        },
      });
    });

    it('displays value', () => {
      expect(findFormInput().element.value).toBe(valueProp);
    });

    itDoesNotModifyCopyEvent();

    describe('when input is clicked', () => {
      it('selects input value', async () => {
        const mockSelect = jest.fn();
        wrapper.vm.$refs.input.$el.select = mockSelect;
        await wrapper.findByLabelText(label).trigger('click');

        expect(mockSelect).toHaveBeenCalled();
      });
    });

    describe('when label is clicked', () => {
      it('selects input value', async () => {
        const mockSelect = jest.fn();
        wrapper.vm.$refs.input.$el.select = mockSelect;
        await wrapper.find('label').trigger('click');

        expect(mockSelect).toHaveBeenCalled();
      });
    });
  });

  describe('when `showToggleVisibilityButton` is `false`', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
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
      expect(findFormInput().element.value).toBe(valueProp);
    });

    itDoesNotModifyCopyEvent();
  });

  describe('when `showCopyButton` is `false`', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          showCopyButton: false,
        },
      });
    });

    it('does not render copy button', () => {
      expect(findCopyButton().exists()).toBe(false);
    });
  });

  it('passes `formInputGroupProps` prop only to the input', () => {
    createComponent({
      propsData: {
        formInputGroupProps: {
          name: 'Foo bar',
          'data-qa-selector': 'Foo bar',
          class: 'Foo bar',
          id: 'Foo bar',
        },
      },
    });

    expect(findFormInput().attributes()).toMatchObject({
      name: 'Foo bar',
      'data-qa-selector': 'Foo bar',
      class: expect.stringContaining('Foo bar'),
      id: 'Foo bar',
    });

    const attributesInputGroup = findFormInputGroup().attributes();
    expect(attributesInputGroup.name).toBeUndefined();
    expect(attributesInputGroup['data-qa-selector']).toBeUndefined();
    expect(attributesInputGroup.class).not.toContain('Foo bar');
    expect(attributesInputGroup.id).toBeUndefined();
  });

  it('passes `copyButtonTitle` prop to `ClipboardButton`', () => {
    createComponent({
      propsData: {
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
