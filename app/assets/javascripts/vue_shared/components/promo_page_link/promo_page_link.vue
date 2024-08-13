<script>
import { GlLink } from '@gitlab/ui';
import { PROMO_URL } from '~/constants';
import { joinPaths } from '~/lib/utils/url_utility';

/**
 * Component to link to GitLab website.
 *
 * @example
 * <promo-page-link href="pricing">
 *   Usage Quotas help.
 * </promo-page-link>
 */
export default {
  name: 'PromoPageLink',
  components: {
    GlLink,
  },
  props: {
    href: {
      type: String,
      required: true,
    },
  },
  computed: {
    compiledHref() {
      return joinPaths(PROMO_URL, this.href);
    },
    attributes() {
      const { href, ...attrs } = this.$attrs;
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
