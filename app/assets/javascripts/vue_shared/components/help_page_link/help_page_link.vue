<script>
import { GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

/**
 * Component to link to GitLab docs.
 *
 * @example
 * <help-page-link href="user/storage_usage_quotas">
 *   Usage Quotas help.
 * <help-page-link>
 */
export default {
  name: 'HelpPageLink',
  components: {
    GlLink,
  },
  props: {
    href: {
      type: String,
      required: true,
    },
    anchor: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    compiledHref() {
      // This component is a wrapper around `helpPagePath`, so it's okay to disable the
      // `local-rules/require-valid-help-page-path` ESLint rule here. Usages of this component are
      // being checked by the `local-rules/vue-require-valid-help-page-link-component` rule.
      // eslint-disable-next-line local-rules/require-valid-help-page-path
      return helpPagePath(this.href, { anchor: this.anchor });
    },
    attributes() {
      const { href, anchor, ...attrs } = this.$attrs;
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
