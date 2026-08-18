import { renderVueComponentForLegacyJS } from '~/render_vue_component_for_legacy_js';

// Written as a Vue 2 style render (a template string would need the runtime
// compiler, which the direct-mount path of the helper does not provide). No
// slot is read: none of the tests below passes children.
const DummyComponent = {
  props: ['foo'],
  render(h) {
    return h('div', { attrs: { 'data-testid': 'dummy', 'data-foo': this.foo } });
  },
};

describe('renderVueComponentForLegacyJS', () => {
  it('returns root element of the given component', () => {
    const el = renderVueComponentForLegacyJS(DummyComponent);

    expect(el.tagName).toBe('DIV');
    expect(el.dataset.testid).toBe('dummy');
    expect(el.dataset.foo).toBe(undefined);
    expect(el.textContent).toBe('');
  });

  it('passes props', () => {
    const el = renderVueComponentForLegacyJS(DummyComponent, { props: { foo: 'bar' } });

    expect(el.dataset.foo).toBe('bar');
  });

  it('passes classes', () => {
    const el = renderVueComponentForLegacyJS(DummyComponent, { class: 'test-class' });

    expect(el.classList).toContain('test-class');
  });
});
