<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { JOB_SIDEBAR } from '../constants';

export default {
  name: 'JobSidebarRetryButton',
  i18n: {
    retryLabel: JOB_SIDEBAR.retry,
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
