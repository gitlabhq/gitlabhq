<script>
import { GlButton, GlDropdown, GlDropdownItem, GlModalDirective } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { JOB_SIDEBAR_COPY } from '~/jobs/constants';

export default {
  name: 'JobSidebarRetryButton',
  i18n: {
    ...JOB_SIDEBAR_COPY,
  },
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
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
  <gl-dropdown
    v-else-if="isManualJob"
    icon="retry"
    category="primary"
    :right="true"
    variant="confirm"
  >
    <gl-dropdown-item :href="href" data-method="post">
      {{ $options.i18n.runAgainJobButtonLabel }}
    </gl-dropdown-item>
    <gl-dropdown-item @click="$emit('updateVariablesClicked')">
      {{ $options.i18n.updateVariables }}
    </gl-dropdown-item>
  </gl-dropdown>
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
