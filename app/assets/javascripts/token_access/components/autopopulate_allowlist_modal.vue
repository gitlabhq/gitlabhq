<script>
import { GlAlert, GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__, sprintf } from '~/locale';

export default {
  name: 'AutopopulateAllowlistModal',
  components: {
    GlAlert,
    GlLink,
    GlModal,
    GlSprintf,
  },
  inject: ['fullPath'],
  props: {
    authLogExceedsLimit: {
      type: Boolean,
      required: true,
    },
    projectAllowlistLimit: {
      type: Number,
      required: true,
    },
    projectName: {
      type: String,
      required: false,
      default: '',
    },
    showModal: {
      type: Boolean,
      required: true,
    },
  },
  apollo: {},
  computed: {
    authLogExceedsLimitMessage() {
      return sprintf(
        s__(
          'CICD|The allowlist can contain a maximum of %{projectAllowlistLimit} groups and projects.',
        ),
        {
          projectAllowlistLimit: this.projectAllowlistLimit,
        },
      );
    },
    modalOptions() {
      return {
        actionPrimary: {
          text: __('Add entries'),
          attributes: {
            variant: 'confirm',
          },
        },
        actionSecondary: {
          text: __('Cancel'),
          attributes: {
            variant: 'default',
          },
        },
      };
    },
    modalTitle() {
      if (this.authLogExceedsLimit) {
        return s__('CICD|Add log entries and compact the allowlist');
      }

      return s__('CICD|Add all authentication log entries to the allowlist');
    },
  },
  methods: {
    autopopulateAllowlist() {
      this.$emit('autopopulate-allowlist');
    },
    hideModal() {
      this.$emit('hide');
    },
  },
  compactionAlgorithmHelpPage: helpPagePath('ci/jobs/ci_job_token', {
    anchor: 'allowlist-compaction',
  }),
};
</script>

<template>
  <gl-modal
    :visible="showModal"
    :title="modalTitle"
    :action-primary="modalOptions.actionPrimary"
    :action-secondary="modalOptions.actionSecondary"
    modal-id="autopopulate-allowlist-modal"
    @primary.prevent="autopopulateAllowlist"
    @secondary="hideModal"
    @canceled="hideModal"
    @hidden="hideModal"
  >
    <div v-if="authLogExceedsLimit">
      <gl-alert variant="warning" class="gl-mb-3" :dismissible="false">
        {{ authLogExceedsLimitMessage }}
      </gl-alert>
      <p data-testid="modal-description">
        <gl-sprintf
          :message="
            s__(
              'CICD|Adding all entries from the authentication log would exceed this limit. GitLab can compact the allowlist with common groups until the entries are within the limit. %{linkStart}What is the compaction algorithm?%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="$options.compactionAlgorithmHelpPage" target="_blank">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </div>
    <div v-else data-testid="modal-description">
      <p>
        <gl-sprintf
          :message="
            s__(
              `CICD|You're about to add all entries from the authentication log to the allowlist for %{projectName}. This will also update the Job Token setting to %{codeStart}This project and any groups and projects in the allowlist%{codeEnd}, if not already set. Duplicate entries will be ignored.`,
            )
          "
        >
          <template #projectName>
            <b>{{ projectName }}</b>
          </template>
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </p>
      <p>
        {{
          s__(
            'CICD|Groups and projects on the allowlist are authorized to use a CI/CD job token to authenticate requests to this project. Entries added from the authentication log can be removed later if needed.',
          )
        }}
      </p>
      <p>
        {{
          s__(
            'CICD|The process might take a moment to complete for large authentication logs or allowlists.',
          )
        }}
      </p>
    </div>
  </gl-modal>
</template>
