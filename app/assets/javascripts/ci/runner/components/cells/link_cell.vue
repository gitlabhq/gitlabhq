<script>
import { GlLink } from '@gitlab/ui';
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

export default {
  name: 'LinkCell',
  mixins: [glListenersMixin],
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
    <slot></slot>
  </component>
</template>
