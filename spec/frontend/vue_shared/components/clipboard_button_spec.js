import { GlButton } from '@gitlab/ui';
import { mount, createWrapper as makeWrapper } from '@vue/test-utils';
import { nextTick } from 'vue';

import { BV_HIDE_TOOLTIP, BV_SHOW_TOOLTIP } from '~/lib/utils/constants';
import initCopyToClipboard, {
  CLIPBOARD_SUCCESS_EVENT,
  CLIPBOARD_ERROR_EVENT,
  I18N_ERROR_MESSAGE,
} from '~/behaviors/copy_to_clipboard';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

jest.mock('lodash/uniqueId', () => (prefix) => (prefix ? `${prefix}1` : 1));

describe('clipboard button', () => {
  let wrapper;

  const createWrapper = (propsData, options = {}) => {
    wrapper = mount(ClipboardButton, {
      propsData,
      ...options,
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  const expectConfirmationTooltip = async ({ event, message }) => {
    const title = 'Copy this value';

    createWrapper({
      text: 'copy me',
      title,
    });

    const rootWrapper = makeWrapper(wrapper.vm.$root);

    const button = findButton();

    expect(button.attributes()).toMatchObject({
      title,
      'aria-label': title,
    });

    await button.trigger(event);

    expect(rootWrapper.emitted(BV_SHOW_TOOLTIP)[0]).toContain('clipboard-button-1');

    expect(button.attributes()).toMatchObject({
      title: message,
      'aria-label': message,
    });

    jest.runAllTimers();
    await nextTick();

    expect(button.attributes()).toMatchObject({
      title,
      'aria-label': title,
    });
    expect(rootWrapper.emitted(BV_HIDE_TOOLTIP)[0]).toContain('clipboard-button-1');
  };

  describe('without gfm', () => {
    beforeEach(() => {
      createWrapper({
        text: 'copy me',
        title: 'Copy this value',
        cssClass: 'btn-danger',
      });
    });

    it('renders a button for clipboard', () => {
      expect(findButton().exists()).toBe(true);
      expect(wrapper.attributes('data-clipboard-text')).toBe('copy me');
    });

    it('should have a tooltip with default values', () => {
      expect(wrapper.attributes('title')).toBe('Copy this value');
    });

    it('should render provided classname', () => {
      expect(wrapper.classes()).toContain('btn-danger');
    });
  });

  describe('with gfm', () => {
    it('sets data-clipboard-text with gfm', () => {
      createWrapper({
        text: 'copy me',
        gfm: '`path/to/file`',
        title: 'Copy this value',
        cssClass: 'btn-danger',
      });

      expect(wrapper.attributes('data-clipboard-text')).toBe(
        '{"text":"copy me","gfm":"`path/to/file`"}',
      );
    });
  });

  it('renders default slot as button text', () => {
    createWrapper(
      {
        text: 'copy me',
        title: 'Copy this value',
      },
      {
        slots: {
          default: 'Foo bar',
        },
      },
    );

    expect(findButton().text()).toBe('Foo bar');
  });

  it('re-emits button events', () => {
    const onClick = jest.fn();
    createWrapper(
      {
        text: 'copy me',
        title: 'Copy this value',
      },
      { listeners: { click: onClick } },
    );

    findButton().trigger('click');

    expect(onClick).toHaveBeenCalled();
  });

  it('passes the category and variant props to the GlButton', () => {
    const category = 'tertiary';
    const variant = 'confirm';

    createWrapper({ title: '', text: '', category, variant });

    expect(findButton().props('category')).toBe(category);
    expect(findButton().props('variant')).toBe(variant);
  });

  describe('confirmation tooltip', () => {
    it('adds `id` and `data-clipboard-handle-tooltip` attributes to button', () => {
      createWrapper({
        text: 'copy me',
        title: 'Copy this value',
      });

      expect(findButton().attributes()).toMatchObject({
        id: 'clipboard-button-1',
        'data-clipboard-handle-tooltip': 'false',
        'aria-live': 'polite',
      });
    });

    it('shows success tooltip after successful copy', () => {
      expectConfirmationTooltip({
        event: CLIPBOARD_SUCCESS_EVENT,
        message: ClipboardButton.i18n.copied,
      });
    });

    it('shows error tooltip after failed copy', () => {
      expectConfirmationTooltip({ event: CLIPBOARD_ERROR_EVENT, message: I18N_ERROR_MESSAGE });
    });
  });

  describe('integration', () => {
    it('actually copies to clipboard', () => {
      initCopyToClipboard();

      document.execCommand = () => {};
      jest.spyOn(document, 'execCommand').mockImplementation(() => true);

      createWrapper(
        {
          text: 'copy me',
          title: 'Copy this value',
        },
        { attachTo: document.body },
      );

      findButton().trigger('click');

      expect(document.execCommand).toHaveBeenCalledWith('copy');
    });
  });
});
