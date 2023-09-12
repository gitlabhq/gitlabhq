<script>
import { GlButton, GlDisclosureDropdown, GlModalDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { s__ } from '~/locale';

export default {
  name: 'JobSidebarRetryButton',
  i18n: {
    retryJobLabel: s__('Job|Retry'),
    runAgainJobButtonLabel: s__('Job|Run again'),
    updateVariables: s__('Job|Update CI/CD variables'),
  },
  components: {
    GlButton,
    GlDisclosureDropdown,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    href: {
      type: String,
      required: true,
    },
    isManualJob: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['hasForwardDeploymentFailure']),
    dropdownItems() {
      return [
        {
          text: this.$options.i18n.runAgainJobButtonLabel,
          href: this.href,
          extraAttrs: {
            'data-method': 'post',
          },
        },
        {
          text: this.$options.i18n.updateVariables,
          action: () => this.$emit('updateVariablesClicked'),
        },
      ];
    },
  },
};
</script>
<template>
  <gl-button
    v-if="hasForwardDeploymentFailure"
    v-gl-modal="modalId"
    :aria-label="$options.i18n.retryJobLabel"
    category="primary"
    variant="confirm"
    icon="retry"
    data-testid="retry-job-button"
  />
  <gl-disclosure-dropdown
    v-else-if="isManualJob"
    icon="retry"
    category="primary"
    placement="right"
    positioning-strategy="fixed"
    variant="confirm"
    :items="dropdownItems"
  />
  <gl-button
    v-else
    :href="href"
    :aria-label="$options.i18n.retryJobLabel"
    category="primary"
    variant="confirm"
    icon="retry"
    data-method="post"
    data-testid="retry-job-link"
  />
</template>
