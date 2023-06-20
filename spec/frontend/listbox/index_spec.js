import { nextTick } from 'vue';
import { getAllByRole, getByTestId } from '@testing-library/dom';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { createWrapper } from '@vue/test-utils';
import htmlRedirectListbox from 'test_fixtures/listbox/redirect_listbox.html';
import { initListbox, parseAttributes } from '~/listbox';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

jest.mock('~/lib/utils/url_utility');

const parsedAttributes = (() => {
  const div = document.createElement('div');
  div.innerHTML = htmlRedirectListbox;
  return parseAttributes(div.firstChild);
})();

describe('initListbox', () => {
  let instance;

  afterEach(() => {
    if (instance) {
      instance.$destroy();
    }
  });

  const setup = (...args) => {
    instance = initListbox(...args);
  };

  it('returns null given no element', () => {
    setup();

    expect(instance).toBe(null);
  });

  it('throws given an invalid element', () => {
    expect(() => setup(document.body)).toThrow();
  });

  describe('given a valid element', () => {
    let onChangeSpy;

    const listbox = () => createWrapper(instance).findComponent(GlCollapsibleListbox);
    const findToggleButton = () => getByTestId(document.body, 'base-dropdown-toggle');
    const findSelectedItems = () => getAllByRole(document.body, 'option', { selected: true });

    beforeEach(async () => {
      setHTMLFixture(htmlRedirectListbox);
      onChangeSpy = jest.fn();
      setup(document.querySelector('.js-redirect-listbox'), { onChange: onChangeSpy });

      await nextTick();
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('returns an instance', () => {
      expect(instance).not.toBe(null);
    });

    it('renders button with selected item text', () => {
      expect(findToggleButton().textContent.trim()).toBe('Bar');
    });

    it('has the correct item selected', () => {
      const selectedItems = findSelectedItems();
      expect(selectedItems).toHaveLength(1);
      expect(selectedItems[0].textContent.trim()).toBe('Bar');
    });

    it('applies additional classes from the original element', () => {
      expect(instance.$el.classList).toContain('test-class-1', 'test-class-2');
    });

    describe.each(parsedAttributes.items)('selecting an item', (item) => {
      beforeEach(async () => {
        listbox().vm.$emit('select', item.value);
        await nextTick();
      });

      it('calls the onChange callback with the item', () => {
        expect(onChangeSpy).toHaveBeenCalledWith(item);
      });

      it('updates the toggle button text', () => {
        expect(findToggleButton().textContent.trim()).toBe(item.text);
      });

      it('marks the item as selected', () => {
        const selectedItems = findSelectedItems();
        expect(selectedItems).toHaveLength(1);
        expect(selectedItems[0].textContent.trim()).toBe(item.text);
      });
    });

    it('passes the "placement" prop through to the underlying component', () => {
      expect(listbox().props('placement')).toBe(parsedAttributes.placement);
    });
  });
});
