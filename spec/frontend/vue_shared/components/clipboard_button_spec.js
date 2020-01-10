import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Icon from '~/vue_shared/components/icon.vue';

describe('clipboard button', () => {
  let wrapper;

  const createWrapper = propsData => {
    wrapper = shallowMount(ClipboardButton, {
      propsData,
      attachToDocument: true,
    });
  };

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
      expect(wrapper.find(GlButton).exists()).toBe(true);
      expect(wrapper.attributes('data-clipboard-text')).toBe('copy me');
      expect(wrapper.find(Icon).props('name')).toBe('duplicate');
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
});
