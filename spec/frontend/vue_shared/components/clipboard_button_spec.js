import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import initCopyToClipboard from '~/behaviors/copy_to_clipboard';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('clipboard button', () => {
  let wrapper;

  const createWrapper = (propsData, options = {}) => {
    wrapper = mount(ClipboardButton, {
      propsData,
      ...options,
    });
  };

  const findButton = () => wrapper.find(GlButton);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

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
