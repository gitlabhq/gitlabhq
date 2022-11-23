<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { JOB_SIDEBAR_COPY } from '~/jobs/constants';

export default {
  name: 'LegacyJobSidebarRetryButton',
  i18n: {
    retryLabel: JOB_SIDEBAR_COPY.retryJobLabel,
  },
  components: {
    GlButton,
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
  },
  computed: {
    ...mapGetters(['hasForwardDeploymentFailure']),
  },
};
</script>
<template>
  <gl-button
    v-if="hasForwardDeploymentFailure"
    v-gl-modal="modalId"
    :aria-label="$options.i18n.retryLabel"
    category="primary"
    variant="confirm"
    icon="retry"
    data-testid="retry-job-button"
  />

  <gl-button
    v-else
    :href="href"
    :aria-label="$options.i18n.retryLabel"
    category="primary"
    variant="confirm"
    icon="retry"
    data-method="post"
    data-testid="retry-job-link"
  />
</template>
