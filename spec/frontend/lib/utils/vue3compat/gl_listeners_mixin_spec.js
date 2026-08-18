import Vue from 'vue';
import { mount } from '@vue/test-utils';
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

const isVue2 = Vue.version.startsWith('2');

describe('glListenersMixin', () => {
  it('returns every parent listener as a callable map entry, on both runtimes', () => {
    let listeners;
    const clickHandler = jest.fn();
    const customHandler = jest.fn();
    const Child = {
      name: 'ProbeListenersChild',
      mixins: [glListenersMixin],
      inheritAttrs: false,
      template: '<div />',
      mounted() {
        listeners = this.glListeners();
      },
    };
    mount({
      name: 'ProbeListenersParent',
      components: { Child },
      template: '<child data-foo="bar" @click="onClick" @custom-event="onCustom" />',
      methods: { onClick: clickHandler, onCustom: customHandler },
    });
    // Attributes never leak into the listeners map.
    expect(Object.values(listeners)).toHaveLength(2);
    // (Reference equality with the original jest.fn cannot be asserted:
    // Vue 2 binds methods, so the map values are bound wrappers there.)
    Object.values(listeners).forEach((handler) => handler('arg'));
    expect(clickHandler).toHaveBeenCalledWith('arg');
    expect(customHandler).toHaveBeenCalledWith('arg');
  });

  it('forwards events exactly once when paired with v-bind="$attrs"', async () => {
    const clickSpy = jest.fn();
    const Child = {
      name: 'PairedChild',
      mixins: [glListenersMixin],
      inheritAttrs: false,
      template: '<button v-bind="$attrs" data-testid="btn" v-on="glListeners()">go</button>',
    };
    const wrapper = mount({
      name: 'PairedParent',
      components: { Child },
      template: '<child data-foo="bar" @click="onClick" />',
      methods: { onClick: clickSpy },
    });
    await wrapper.find('[data-testid="btn"]').trigger('click');
    expect(wrapper.find('[data-testid="btn"]').attributes('data-foo')).toBe('bar');
    // On plain Vue 3 the listener arrives twice (v-bind="$attrs" as onClick
    // and the v-on object); Vue's mergeProps skips the second registration
    // because it is the same reference under the same key.
    expect(clickSpy).toHaveBeenCalledTimes(1);
  });

  it('forwards events exactly once at a solo site (no v-bind="$attrs")', async () => {
    const clickSpy = jest.fn();
    const Child = {
      name: 'SoloChild',
      mixins: [glListenersMixin],
      template: '<button data-testid="btn" v-on="glListeners()">go</button>',
    };
    const wrapper = mount({
      name: 'SoloParent',
      components: { Child },
      template: '<child @click="onClick" />',
      methods: { onClick: clickSpy },
    });
    await wrapper.find('[data-testid="btn"]').trigger('click');
    expect(clickSpy).toHaveBeenCalledTimes(1);
  });

  it('forwards kebab-case and update:model-value component events to the parent once', () => {
    const customSpy = jest.fn();
    const updateSpy = jest.fn();
    const Inner = {
      name: 'ProbeInner',
      template: '<div>inner</div>',
    };
    const Child = {
      name: 'ForwardChild',
      components: { Inner },
      mixins: [glListenersMixin],
      template: '<inner v-on="glListeners()" />',
    };
    const wrapper = mount({
      name: 'ForwardParent',
      components: { Child },
      template: '<child @custom-event="onCustom" @update:model-value="onUpdate" />',
      methods: { onCustom: customSpy, onUpdate: updateSpy },
    });
    const inner = wrapper.findComponent({ name: 'ProbeInner' });
    inner.vm.$emit('custom-event', 'payload');
    inner.vm.$emit('update:model-value', 'value');
    expect(customSpy).toHaveBeenCalledTimes(1);
    expect(customSpy).toHaveBeenCalledWith('payload');
    expect(updateSpy).toHaveBeenCalledTimes(1);
    expect(updateSpy).toHaveBeenCalledWith('value');
  });

  it('forwards multiple handlers for the same event without duplication', async () => {
    const spy1 = jest.fn();
    const spy2 = jest.fn();
    const Child = {
      name: 'ArrayChild',
      mixins: [glListenersMixin],
      inheritAttrs: false,
      template: '<button v-bind="$attrs" data-testid="btn" v-on="glListeners()">go</button>',
    };
    const wrapper = mount({
      name: 'ArrayParent',
      components: { Child },
      template: '<child v-on="{ click: [h1, h2] }" />',
      computed: {
        h1() {
          return spy1;
        },
        h2() {
          return spy2;
        },
      },
    });
    await wrapper.find('[data-testid="btn"]').trigger('click');
    expect(spy1).toHaveBeenCalledTimes(1);
    expect(spy2).toHaveBeenCalledTimes(1);
  });

  it('supports the spread-and-override shape', async () => {
    const parentSpy = jest.fn();
    const overrideSpy = jest.fn();
    const Child = {
      name: 'SpreadChild',
      mixins: [glListenersMixin],
      // The overridden event MUST be declared in `emits`: on plain Vue 3 the
      // parent's own handler would otherwise still reach the root element
      // through attribute fallthrough, defeating the override. Declaring the
      // emit removes it from $attrs (and fallthrough); Vue 2 ignores the
      // option.
      emits: ['click'],
      template:
        '<button data-testid="btn" v-on="{ ...glListeners(), click: onOwnClick }">go</button>',
      methods: {
        onOwnClick() {
          overrideSpy();
        },
      },
    };
    const wrapper = mount({
      name: 'SpreadParent',
      components: { Child },
      template: '<child @click="onClick" @keydown="onKeydown" />',
      methods: { onClick: parentSpy, onKeydown: parentSpy },
    });
    await wrapper.find('[data-testid="btn"]').trigger('click');
    expect(overrideSpy).toHaveBeenCalledTimes(1);
    expect(parentSpy).not.toHaveBeenCalled();
    await wrapper.find('[data-testid="btn"]').trigger('keydown');
    expect(parentSpy).toHaveBeenCalledTimes(1);
  });

  it('still sees listeners for events declared in emits (Vue 2 $listeners parity)', () => {
    // On plain Vue 3, $attrs drops listeners for emits-declared events, but
    // Vue 2's $listeners always contains every parent listener — the map
    // must be derived from the vnode props (wizard_stepper.vue relies on
    // this: it declares emits and presence-checks the listener).
    let present;
    const Child = {
      name: 'EmitsDeclaredChild',
      mixins: [glListenersMixin],
      emits: ['step-click'],
      template: '<div />',
      mounted() {
        present = Boolean(this.glListener('step-click'));
      },
    };
    mount({
      name: 'EmitsDeclaredParent',
      components: { Child },
      template: '<child @step-click="noop" />',
      methods: { noop() {} },
    });
    expect(present).toBe(true);
  });

  describe('glListener', () => {
    // The key spelling differs per runtime: Vue 2 keeps the event name as
    // the consumer wrote it (`step-click`), @vue/compat and plain Vue 3
    // camelize (`stepClick`). glListener normalizes the lookup.
    it('finds a kebab-named listener and reports absent ones, on both runtimes', () => {
      let present;
      let absent;
      const handler = jest.fn();
      const Child = {
        name: 'AccessorChild',
        mixins: [glListenersMixin],
        inheritAttrs: false,
        template: '<div />',
        mounted() {
          present = this.glListener('step-click');
          absent = this.glListener('other-event');
        },
      };
      mount({
        name: 'AccessorParent',
        components: { Child },
        template: '<child @step-click="onStepClick" />',
        methods: { onStepClick: handler },
      });
      expect(present).toEqual(expect.any(Function));
      present('payload');
      expect(handler).toHaveBeenCalledWith('payload');
      expect(absent).toBeUndefined();
    });
  });

  if (isVue2) {
    it('documents why bare v-bind="$attrs" is not a substitute on Vue 2: $attrs has no listeners', () => {
      let attrsKeys;
      const Probe = {
        name: 'ProbeNaive',
        inheritAttrs: false,
        template: '<div />',
        mounted() {
          attrsKeys = Object.keys(this.$attrs);
        },
      };
      mount({
        name: 'ProbeNaiveParent',
        components: { Probe },
        template: '<probe data-foo="bar" @click="noop" />',
        methods: { noop() {} },
      });
      expect(attrsKeys).toEqual(['data-foo']);
    });
  }
});
