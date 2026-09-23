<script>
import {
  GlButtonGroup,
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlModalDirective,
} from '@gitlab/ui';
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
    retryWithModifiedValue: s__('Job|Retry job with modified values'),
  },
  components: {
    GlButtonGroup,
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlModal: GlModalDirective,
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
    hasInputs: {
      type: Boolean,
      required: false,
      default: false,
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
  emits: ['update-variables-clicked'],
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    ...mapGetters(['hasForwardDeploymentFailure']),
    showRetryWithModifiedValues() {
      return (this.isManualJob && this.canSetPipelineVariables) || this.hasInputs;
    },
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
  <gl-button-group>
    <gl-button
      v-if="hasForwardDeploymentFailure"
      v-gl-modal="modalId"
      :aria-label="retryButtonTitle"
      category="primary"
      variant="confirm"
      data-testid="retry-job-button"
    >
      {{ retryButtonTitle }}
    </gl-button>

    <gl-button
      v-else-if="isManualJob"
      :aria-label="retryButtonTitle"
      category="primary"
      variant="confirm"
      data-testid="manual-run-again-btn"
      :loading="isLoading"
      @click="retryManualJob"
    >
      {{ retryButtonTitle }}
    </gl-button>

    <gl-button
      v-else
      :href="href"
      :aria-label="retryButtonTitle"
      category="primary"
      variant="confirm"
      data-method="post"
      data-testid="retry-job-link"
    >
      {{ retryButtonTitle }}
    </gl-button>

    <gl-disclosure-dropdown
      v-if="showRetryWithModifiedValues"
      category="primary"
      variant="confirm"
      placement="bottom-end"
      :aria-label="$options.i18n.retryWithModifiedValue"
    >
      <gl-disclosure-dropdown-item
        data-testid="manual-run-edit-btn"
        @action="$emit('update-variables-clicked')"
      >
        <template #list-item> {{ $options.i18n.retryWithModifiedValue }}</template>
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown>
  </gl-button-group>
</template>
