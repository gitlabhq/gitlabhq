import { nextTick } from 'vue';
import { getAllByRole, getByRole } from '@testing-library/dom';
import { GlDropdown } from '@gitlab/ui';
import { createWrapper } from '@vue/test-utils';
import { initListbox, parseAttributes } from '~/listbox';
import { getFixture, setHTMLFixture } from 'helpers/fixtures';

jest.mock('~/lib/utils/url_utility');

const fixture = getFixture('listbox/redirect_listbox.html');

const parsedAttributes = (() => {
  const div = document.createElement('div');
  div.innerHTML = fixture;
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

  // TODO: Rewrite these finders to use better semantics once the
  // implementation is switched to GlListbox
  // https://gitlab.com/gitlab-org/gitlab/-/issues/348738
  const findToggleButton = () => document.body.querySelector('.gl-dropdown-toggle');
  const findItem = (text) => getByRole(document.body, 'menuitem', { name: text });
  const findItems = () => getAllByRole(document.body, 'menuitem');
  const findSelectedItems = () =>
    findItems().filter(
      (menuitem) =>
        !menuitem
          .querySelector('.gl-new-dropdown-item-check-icon')
          .classList.contains('gl-visibility-hidden'),
    );

  it('returns null given no element', () => {
    setup();

    expect(instance).toBe(null);
  });

  it('throws given an invalid element', () => {
    expect(() => setup(document.body)).toThrow();
  });

  describe('given a valid element', () => {
    let onChangeSpy;

    beforeEach(async () => {
      setHTMLFixture(fixture);
      onChangeSpy = jest.fn();
      setup(document.querySelector('.js-redirect-listbox'), { onChange: onChangeSpy });

      await nextTick();
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

    describe.each(parsedAttributes.items)('clicking on an item', (item) => {
      beforeEach(async () => {
        findItem(item.text).click();

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

    it('passes the "right" prop through to the underlying component', () => {
      const wrapper = createWrapper(instance).findComponent(GlDropdown);
      expect(wrapper.props('right')).toBe(parsedAttributes.right);
    });
  });
});
