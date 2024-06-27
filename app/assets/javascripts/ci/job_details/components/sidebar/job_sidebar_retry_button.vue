<script>
import { GlButton, GlDisclosureDropdown, GlModalDirective } from '@gitlab/ui';
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
    confirmationMessage: {
      type: String,
      required: false,
      default: null,
    },
    jobName: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['hasForwardDeploymentFailure']),
    dropdownItems() {
      return [
        {
          text: this.$options.i18n.runAgainJobButtonLabel,
          action: async () => {
            if (this.confirmationMessage !== null) {
              const confirmed = await confirmJobConfirmationMessage(
                this.jobName,
                this.confirmationMessage,
              );
              if (!confirmed) {
                return;
              }
            }
            axios
              .post(this.href)
              .then((response) => {
                visitUrl(response.request.responseURL);
              })
              .catch(() => {
                createAlert({
                  message: __('An error occurred while making the request.'),
                });
              });
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
    placement="bottom-end"
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
