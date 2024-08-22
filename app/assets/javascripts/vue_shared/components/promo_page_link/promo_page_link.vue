<script>
import { GlLink } from '@gitlab/ui';
import { PROMO_URL } from '~/constants';
import { joinPaths } from '~/lib/utils/url_utility';

/**
 * Component to link to GitLab website.
 *
 * @example
 * <promo-page-link path="pricing">
 *   Usage Quotas help.
 * </promo-page-link>
 */
export default {
  name: 'PromoPageLink',
  components: {
    GlLink,
  },
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
  <gl-link v-bind="attributes" :href="compiledHref" v-on="$listeners">
    <slot></slot>
  </gl-link>
</template>
