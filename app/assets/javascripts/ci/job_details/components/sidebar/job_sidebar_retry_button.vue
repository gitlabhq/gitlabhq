<script>
import { GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { confirmJobConfirmationMessage } from '~/ci/pipeline_details/graph/utils';

export default {
  name: 'JobSidebarRetryButton',
  i18n: {
    updateVariables: s__('Job|Update CI/CD variables'),
  },
  components: {
    GlButton,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: ['canSetPipelineVariables'],
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
    confirmationMessage: {
      type: String,
      required: false,
      default: null,
    },
    jobName: {
      type: String,
      required: true,
    },
    retryButtonTitle: {
      type: String,
      required: false,
      default: __('Retry'),
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    ...mapGetters(['hasForwardDeploymentFailure']),
  },
  methods: {
    async retryManualJob() {
      if (this.confirmationMessage) {
        const confirmed = await confirmJobConfirmationMessage(
          this.jobName,
          this.confirmationMessage,
        );
        if (!confirmed) return;
      }

      try {
        this.isLoading = true;
        const { request } = await axios.post(this.href);
        visitUrl(request.responseURL);
      } catch {
        createAlert({ message: __('There was an error retrying the job.') });
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>
<template>
  <gl-button
    v-if="hasForwardDeploymentFailure"
    v-gl-modal="modalId"
    v-gl-tooltip.bottom
    :title="retryButtonTitle"
    :aria-label="retryButtonTitle"
    category="primary"
    variant="confirm"
    icon="retry"
    data-testid="retry-job-button"
  />
  <div v-else-if="isManualJob" class="gl-flex gl-gap-3">
    <gl-button
      v-if="canSetPipelineVariables"
      v-gl-tooltip.bottom
      :title="$options.i18n.updateVariables"
      :aria-label="$options.i18n.updateVariables"
      category="secondary"
      variant="confirm"
      icon="pencil-square"
      data-testid="manual-run-edit-btn"
      @click="$emit('updateVariablesClicked')"
    />
    <gl-button
      v-gl-tooltip.bottom
      :title="retryButtonTitle"
      :aria-label="retryButtonTitle"
      category="primary"
      variant="confirm"
      icon="retry"
      data-testid="manual-run-again-btn"
      :loading="isLoading"
      @click="retryManualJob"
    />
  </div>

  <gl-button
    v-else
    v-gl-tooltip.bottom
    :href="href"
    :title="retryButtonTitle"
    :aria-label="retryButtonTitle"
    category="primary"
    variant="confirm"
    icon="retry"
    data-method="post"
    data-testid="retry-job-link"
  />
</template>
