import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { RedirectScrollKeysToPanelDirective } from '~/vue_shared/directives/redirect_scroll_keys_to_panel';
import { getDefaultScrollingPanel } from '~/lib/utils/panels';

jest.mock('~/lib/utils/panels');

describe('RedirectScrollKeysToPanelDirective', () => {
  let el;
  let panel;

  beforeEach(() => {
    setHTMLFixture(`
      <header class="js-el" tabindex="0">top bar</header>
      <div class="js-static-panel-inner"></div>
    `);

    el = document.querySelector('.js-el');
    panel = document.querySelector('.js-static-panel-inner');
    jest.spyOn(panel, 'focus').mockImplementation(() => {});
    getDefaultScrollingPanel.mockReturnValue(panel);

    RedirectScrollKeysToPanelDirective.bind(el);
  });

  afterEach(() => {
    RedirectScrollKeysToPanelDirective.unbind(el);
    resetHTMLFixture();
  });

  const pressKeyOn = (target, key) => {
    target.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true }));
  };

  it.each(['ArrowDown', 'ArrowUp', 'PageDown', 'PageUp', 'Home', 'End'])(
    'focuses the panel so the browser scrolls it when %s is pressed on the element',
    (key) => {
      pressKeyOn(el, key);
      expect(panel.focus).toHaveBeenCalled();
    },
  );

  it('does not act on non-scroll keys', () => {
    pressKeyOn(el, 'Enter');
    expect(panel.focus).not.toHaveBeenCalled();
  });

  it('acts on keydowns bubbling from a non-interactive descendant (e.g. a header link)', () => {
    const link = document.createElement('a');
    link.href = '/foo';
    el.appendChild(link);
    pressKeyOn(link, 'ArrowDown');
    expect(panel.focus).toHaveBeenCalled();
  });

  it.each([
    ['a button (e.g. a dropdown toggle)', () => document.createElement('button')],
    ['an input', () => document.createElement('input')],
    ['a textarea', () => document.createElement('textarea')],
    [
      'a listbox option',
      () => {
        const option = document.createElement('div');
        option.setAttribute('role', 'option');
        return option;
      },
    ],
  ])('does not act when the key comes from %s', (_, createControl) => {
    const control = createControl();
    el.appendChild(control);
    pressKeyOn(control, 'ArrowDown');
    expect(panel.focus).not.toHaveBeenCalled();
  });

  it('makes the panel focusable transiently and removes the tabindex on blur', () => {
    pressKeyOn(el, 'ArrowDown');
    expect(panel.getAttribute('tabindex')).toBe('-1');

    panel.dispatchEvent(new FocusEvent('blur'));
    expect(panel.hasAttribute('tabindex')).toBe(false);
  });

  it('does not add a tabindex when the panel already has one', () => {
    panel.setAttribute('tabindex', '0');
    pressKeyOn(el, 'ArrowDown');
    panel.dispatchEvent(new FocusEvent('blur'));
    expect(panel.getAttribute('tabindex')).toBe('0');
  });

  it('does nothing when there is no scrolling panel', () => {
    getDefaultScrollingPanel.mockReturnValue(null);
    expect(() => pressKeyOn(el, 'ArrowDown')).not.toThrow();
  });

  it('removes the listener on unbind', () => {
    RedirectScrollKeysToPanelDirective.unbind(el);
    pressKeyOn(el, 'ArrowDown');
    expect(panel.focus).not.toHaveBeenCalled();
  });
});
