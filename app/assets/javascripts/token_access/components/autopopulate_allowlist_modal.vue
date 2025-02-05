<script>
import { GlAlert, GlModal, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import autopopulateAllowlistMutation from '../graphql/mutations/autopopulate_allowlist.mutation.graphql';

export default {
  name: 'AutopopulateAllowlistModal',
  components: {
    GlAlert,
    GlModal,
    GlSprintf,
  },
  inject: ['fullPath'],
  props: {
    projectName: {
      type: String,
      required: true,
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
};
</script>

<template>
  <gl-modal
    :visible="showModal"
    :title="s__('CICD|Add all authentication log entries to the allowlist')"
    :action-primary="modalOptions.actionPrimary"
    :action-secondary="modalOptions.actionSecondary"
    modal-id="autopopulate-allowlist-modal"
    @primary.prevent="autopopulateAllowlist"
    @secondary="hideModal"
    @canceled="hideModal"
  >
    <gl-alert v-if="errorMessage" variant="danger" class="gl-mb-3 gl-pb-0" :dismissible="false">
      <p>
        {{ errorMessage }}
      </p>
    </gl-alert>
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
  </gl-modal>
</template>
