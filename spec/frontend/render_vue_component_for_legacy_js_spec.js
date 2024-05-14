import { renderVueComponentForLegacyJS } from '~/render_vue_component_for_legacy_js';

const DummyComponent = {
  props: ['foo'],
  render(h) {
    return h(
      'div',
      { attrs: { 'data-testid': 'dummy', 'data-foo': this.foo } },
      this.$scopedSlots.default?.(),
    );
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
