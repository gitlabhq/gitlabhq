<script>
import { GlAlert, GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__, sprintf } from '~/locale';
import autopopulateAllowlistMutation from '../graphql/mutations/autopopulate_allowlist.mutation.graphql';

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
  data() {
    return {
      errorMessage: false,
      isAutopopulating: false,
    };
  },
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
            loading: this.isAutopopulating,
          },
        },
        actionSecondary: {
          text: __('Cancel'),
          attributes: {
            variant: 'default',
            disabled: this.isAutopopulating,
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
    async autopopulateAllowlist() {
      this.isAutopopulating = true;
      this.errorMessage = null;

      try {
        const {
          data: {
            ciJobTokenScopeAutopopulateAllowlist: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: autopopulateAllowlistMutation,
          variables: {
            projectPath: this.fullPath,
          },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }

        this.$emit('refetch-allowlist');
        this.hideModal();
        this.$toast.show(
          s__('CICD|Authentication log entries were successfully added to the allowlist.'),
        );
      } catch (error) {
        this.errorMessage =
          error?.message ||
          s__(
            'CICD|An error occurred while adding the authentication log entries. Please try again.',
          );
      } finally {
        this.isAutopopulating = false;
      }
    },
    hideModal() {
      this.errorMessage = null;
      this.$emit('hide');
    },
  },
  compactionAlgorithmHelpPage: helpPagePath('ci/jobs/ci_job_token', {
    anchor: 'auto-populate-a-projects-allowlist',
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
    <gl-alert v-if="errorMessage" variant="danger" class="gl-mb-3" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>
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
              `CICD|You're about to add all entries from the authentication log to the allowlist for %{projectName}. Duplicate entries will be ignored.`,
            )
          "
        >
          <template #projectName>
            <b>{{ projectName }}</b>
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
            'CICD|The process to add entries could take a moment to complete with large logs or allowlists.',
          )
        }}
      </p>
    </div>
  </gl-modal>
</template>
