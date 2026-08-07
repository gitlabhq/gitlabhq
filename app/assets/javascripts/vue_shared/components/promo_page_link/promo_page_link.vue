<script>
import { GlLink } from '@gitlab/ui';
import { PROMO_URL } from '~/constants';
import { joinPaths } from '~/lib/utils/url_utility';
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

/**
 * Component to link to GitLab website.
 *
 * @example
 * <promo-page-link path="pricing">
 *   Usage quotas help.
 * </promo-page-link>
 */
export default {
  name: 'PromoPageLink',
  components: {
    GlLink,
  },
  mixins: [glListenersMixin],
  props: {
    path: {
      type: String,
      required: true,
    },
  },
  computed: {
    compiledHref() {
      return joinPaths(PROMO_URL, this.path);
    },
    attributes() {
      const { path, ...attrs } = this.$attrs;
      return attrs;
    },
  },
};
</script>
<template>
  <gl-link v-bind="attributes" :href="compiledHref" v-on="glListeners()">
    <slot></slot>
  </gl-link>
</template>
