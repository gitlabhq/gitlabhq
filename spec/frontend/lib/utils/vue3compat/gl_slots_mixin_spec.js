import Vue from 'vue';
import { mount } from '@vue/test-utils';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

const isVue2 = Vue.version.startsWith('2');

describe('glSlotsMixin', () => {
  const Child = {
    name: 'ProbeSlotChild',
    mixins: [glSlotsMixin],
    template: `
      <div>
        <span data-testid="names">{{ Object.keys(glSlots()).sort().join(',') }}</span>
        <span data-testid="has-scoped">{{ Boolean(glSlots().scoped) }}</span>
        <span data-testid="has-plain">{{ Boolean(glSlots().plain) }}</span>
        <span data-testid="has-absent">{{ Boolean(glSlots().absent) }}</span>
        <slot name="scoped" :payload="'from-child'"></slot>
        <slot name="plain"></slot>
      </div>
    `,
  };

  const createParent = () =>
    mount({
      name: 'ProbeSlotParent',
      components: { Child },
      template: `
        <child>
          <template #scoped="{ payload }"><i>{{ payload }}</i></template>
          <template #plain><b>plain</b></template>
        </child>
      `,
    });

  it('exposes every provided slot as a function, on both runtimes', () => {
    const wrapper = createParent();
    expect(wrapper.find('[data-testid="names"]').text()).toBe('plain,scoped');
    expect(wrapper.find('[data-testid="has-scoped"]').text()).toBe('true');
    expect(wrapper.find('[data-testid="has-plain"]').text()).toBe('true');
    expect(wrapper.find('[data-testid="has-absent"]').text()).toBe('false');
    expect(wrapper.text()).toContain('from-child');
  });

  it('supports the slot pass-through iteration shape', () => {
    const Inner = {
      name: 'ProbeInner',
      template: `<div><slot name="a" :val="1"></slot><slot name="b"></slot></div>`,
    };
    const Middle = {
      name: 'ProbeMiddle',
      components: { Inner },
      mixins: [glSlotsMixin],
      template: `
        <inner>
          <template v-for="(_, name) in glSlots()" #[name]="slotProps">
            <slot :name="name" v-bind="slotProps"></slot>
          </template>
        </inner>
      `,
    };
    const wrapper = mount({
      name: 'ProbeOuter',
      components: { Middle },
      template: `
        <middle>
          <template #a="{ val }"><i data-testid="a">{{ val }}</i></template>
          <template #b><b data-testid="b">bee</b></template>
        </middle>
      `,
    });
    expect(wrapper.find('[data-testid="a"]').text()).toBe('1');
    expect(wrapper.find('[data-testid="b"]').text()).toBe('bee');
  });

  if (isVue2) {
    it('documents why Vue 2 $slots is not a substitute: it misses slots passed with slot props', () => {
      let naiveSlots;
      let glSlotsResult;
      const Probe = {
        name: 'ProbeNaive',
        mixins: [glSlotsMixin],
        template: `<div><slot name="scoped" :payload="1"></slot></div>`,
        mounted() {
          naiveSlots = Boolean(this.$slots.scoped);
          glSlotsResult = Boolean(this.glSlots().scoped);
        },
      };
      mount({
        name: 'ProbeNaiveParent',
        components: { Probe },
        template: `<probe><template #scoped="{ payload }">{{ payload }}</template></probe>`,
      });
      expect(naiveSlots).toBe(false);
      expect(glSlotsResult).toBe(true);
    });
  }
});
