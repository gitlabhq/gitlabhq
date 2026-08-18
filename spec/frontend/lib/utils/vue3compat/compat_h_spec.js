import { mount } from '@vue/test-utils';
import { compatH } from '~/lib/utils/vue3compat/compat_h';
import { normalizeRender, getSlotFunction } from '~/lib/utils/vue3compat/normalize_render';

describe('compatH', () => {
  const mountRender = (render) => mount(normalizeRender({ render }));

  describe('elements', () => {
    it('renders attrs, class and style from Vue 2 data', () => {
      const wrapper = mountRender(() =>
        compatH(
          'div',
          {
            attrs: { id: 'my-id', 'data-testid': 'my-el' },
            class: { active: true, inactive: false },
            staticClass: 'static',
            style: { color: 'red' },
          },
          'content',
        ),
      );

      const el = wrapper.find('[data-testid="my-el"]');
      expect(el.attributes('id')).toBe('my-id');
      expect(el.classes()).toEqual(expect.arrayContaining(['static', 'active']));
      expect(el.classes()).not.toContain('inactive');
      expect(el.element.style.color).toBe('red');
      expect(el.text()).toBe('content');
    });

    it('renders domProps', () => {
      const wrapper = mountRender(() => compatH('div', { domProps: { innerHTML: '<b>bold</b>' } }));

      expect(wrapper.find('b').text()).toBe('bold');
    });

    it('attaches on listeners', () => {
      const clickHandler = jest.fn();
      const wrapper = mountRender(() => compatH('button', { on: { click: clickHandler } }, 'go'));

      wrapper.find('button').trigger('click');

      expect(clickHandler).toHaveBeenCalledTimes(1);
    });

    it('renders nested element children arrays', () => {
      const wrapper = mountRender(() =>
        compatH('ul', { attrs: { 'data-testid': 'list' } }, [
          compatH('li', undefined, 'one'),
          compatH('li', undefined, 'two'),
        ]),
      );

      expect(wrapper.findAll('li').wrappers.map((li) => li.text())).toEqual(['one', 'two']);
    });
  });

  describe('components', () => {
    // Built on compatH itself: the Vue 2 jest lane runs the runtime-only
    // build, so the fixture cannot use an inline template.
    const Child = normalizeRender({
      name: 'CompatHChild',
      props: {
        message: {
          type: String,
          required: true,
        },
      },
      render() {
        return compatH('div', undefined, [
          compatH('span', { attrs: { 'data-testid': 'message' } }, this.message),
          getSlotFunction(this, 'default')?.(),
          getSlotFunction(this, 'named')?.({ scoped: 'scope-value' }),
          compatH('button', {
            attrs: { 'data-testid': 'camel' },
            on: { click: () => this.$emit('camelEvent', 'camel-payload') },
          }),
          compatH('button', {
            attrs: { 'data-testid': 'kebab' },
            on: { click: () => this.$emit('kebab-event', 'kebab-payload') },
          }),
        ]);
      },
    });

    it('passes props', () => {
      const wrapper = mountRender(() => compatH(Child, { props: { message: 'from-props' } }));

      expect(wrapper.find('[data-testid="message"]').text()).toBe('from-props');
    });

    it('invokes camelCase on listeners for camelCase emits', () => {
      const handler = jest.fn();
      const wrapper = mountRender(() =>
        compatH(Child, { props: { message: 'm' }, on: { camelEvent: handler } }),
      );

      wrapper.find('[data-testid="camel"]').trigger('click');

      expect(handler).toHaveBeenCalledWith('camel-payload');
    });

    it('invokes kebab-case on listeners for kebab-case emits', () => {
      const handler = jest.fn();
      const wrapper = mountRender(() =>
        compatH(Child, { props: { message: 'm' }, on: { 'kebab-event': handler } }),
      );

      wrapper.find('[data-testid="kebab"]').trigger('click');

      expect(handler).toHaveBeenCalledWith('kebab-payload');
    });

    it('keeps both on and nativeOn handlers for the same event key', () => {
      const onHandler = jest.fn();
      const nativeHandler = jest.fn();
      // Declares the emit so the merged listener stays on the component
      // channel on Vue 3 (no attr fallthrough double-fire); on Vue 2 the two
      // channels are separate — `on` fires via $emit, `nativeOn` via the
      // native click on the root element.
      const NativeChild = normalizeRender({
        name: 'CompatHNativeChild',
        emits: ['click'],
        render() {
          return compatH('button', {
            attrs: { 'data-testid': 'native-child' },
            on: { click: () => this.$emit('click') },
          });
        },
      });

      const wrapper = mountRender(() =>
        compatH(NativeChild, { on: { click: onHandler }, nativeOn: { click: nativeHandler } }),
      );

      wrapper.find('[data-testid="native-child"]').trigger('click');

      expect(onHandler).toHaveBeenCalledTimes(1);
      expect(nativeHandler).toHaveBeenCalledTimes(1);
    });

    it('renders raw children as the default slot', () => {
      const wrapper = mountRender(() =>
        compatH(Child, { props: { message: 'm' } }, [compatH('em', undefined, 'child')]),
      );

      expect(wrapper.find('em').text()).toBe('child');
    });

    it('renders scopedSlots with their scope', () => {
      const wrapper = mountRender(() =>
        compatH(Child, {
          props: { message: 'm' },
          scopedSlots: {
            named: ({ scoped }) => compatH('strong', undefined, scoped),
          },
        }),
      );

      expect(wrapper.find('strong').text()).toBe('scope-value');
    });

    it('renders scopedSlots together with raw default children', () => {
      const wrapper = mountRender(() =>
        compatH(
          Child,
          {
            props: { message: 'm' },
            scopedSlots: {
              named: () => compatH('strong', undefined, 'named-slot'),
            },
          },
          [compatH('em', undefined, 'default-slot')],
        ),
      );

      expect(wrapper.find('em').text()).toBe('default-slot');
      expect(wrapper.find('strong').text()).toBe('named-slot');
    });
  });

  describe('inside components rendering their own slots', () => {
    it('forwards slots read via getSlotFunction', () => {
      const Renderless = normalizeRender({
        name: 'CompatHRenderless',
        render() {
          return compatH('div', { attrs: { 'data-testid': 'outer' } }, [
            getSlotFunction(this)({ value: 42 }),
          ]);
        },
      });

      const wrapper = mount(Renderless, {
        scopedSlots: {
          default: '<i>{{ props.value }}</i>',
        },
      });

      expect(wrapper.find('i').text()).toBe('42');
    });
  });
});
