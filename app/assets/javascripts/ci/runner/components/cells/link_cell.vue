<script>
import { GlLink } from '@gitlab/ui';
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'LinkCell',
  mixins: [glListenersMixin, glSlotsMixin],
  props: {
    href: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    component() {
      if (this.href) {
        return GlLink;
      }
      return 'span';
    },
  },
};
</script>

<template>
  <component :is="component" :href="href" v-bind="$attrs" v-on="glListeners()">
    <template v-if="glSlots().default" #default><slot></slot></template>
  </component>
</template>
