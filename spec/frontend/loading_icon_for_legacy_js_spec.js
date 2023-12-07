import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';

describe('loadingIconForLegacyJS', () => {
  it('sets the correct defaults', () => {
    const el = loadingIconForLegacyJS();

    expect(el.tagName).toBe('DIV');
    expect(el.className).toBe('gl-spinner-container');
    expect(el.querySelector('.gl-spinner-sm')).toEqual(expect.any(HTMLElement));
    expect(el.querySelector('.gl-spinner-dark')).toEqual(expect.any(HTMLElement));
    expect(el.getAttribute('aria-label')).toEqual('Loading');
    expect(el.getAttribute('role')).toBe('status');
  });

  it('renders a span if inline = true', () => {
    expect(loadingIconForLegacyJS({ inline: true }).tagName).toBe('SPAN');
  });

  it('can render a different size', () => {
    const el = loadingIconForLegacyJS({ size: 'lg' });

    expect(el.querySelector('.gl-spinner-lg')).toEqual(expect.any(HTMLElement));
  });

  it('can render a different color', () => {
    const el = loadingIconForLegacyJS({ color: 'light' });

    expect(el.querySelector('.gl-spinner-light')).toEqual(expect.any(HTMLElement));
  });

  it('can render a different aria-label', () => {
    const el = loadingIconForLegacyJS({ label: 'Foo' });

    expect(el.getAttribute('aria-label')).toEqual('Foo');
  });

  it('can render additional classes', () => {
    const classes = ['foo', 'bar'];
    const el = loadingIconForLegacyJS({ classes });

    expect(el.classList).toContain(...classes);
  });
});
