<script>
import { GlButton, GlLink, GlModalDirective } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { JOB_SIDEBAR } from '../constants';

export default {
  name: 'JobSidebarRetryButton',
  i18n: {
    retryLabel: JOB_SIDEBAR.retry,
  },
  components: {
    GlButton,
    GlLink,
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
    >{{ $options.i18n.retryLabel }}</gl-button
  >
  <gl-link v-else :href="href" class="btn gl-button btn-confirm" data-method="post" rel="nofollow"
    >{{ $options.i18n.retryLabel }}
  </gl-link>
</template>
