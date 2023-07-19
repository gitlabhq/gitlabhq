<script>
import { GlDisclosureDropdownItem, GlLoadingIcon, GlModal, GlModalDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import runnersRegistrationTokenResetMutation from '~/ci/runner/graphql/list/runners_registration_token_reset.mutation.graphql';
import { captureException } from '~/ci/runner/sentry_utils';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '../../constants';

const i18n = {
  modalAction: s__('Runners|Reset token'),
  modalCancel: __('Cancel'),
  modalCopy: __('Are you sure you want to reset the registration token?'),
  modalTitle: __('Reset registration token'),
};

export default {
  name: 'RunnerRegistrationTokenReset',
  i18n,
  components: {
    GlDisclosureDropdownItem,
    GlLoadingIcon,
    GlModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: {
    groupId: {
      default: null,
    },
    projectId: {
      default: null,
    },
  },
  modalId: 'token-reset-modal',
  props: {
    type: {
      type: String,
      required: true,
      validator(type) {
        return [INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE].includes(type);
      },
    },
  },
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    resetTokenInput() {
      switch (this.type) {
        case INSTANCE_TYPE:
          return {
            type: this.type,
          };
        case GROUP_TYPE:
          return {
            id: convertToGraphQLId(TYPENAME_GROUP, this.groupId),
            type: this.type,
          };
        case PROJECT_TYPE:
          return {
            id: convertToGraphQLId(TYPENAME_PROJECT, this.projectId),
            type: this.type,
          };
        default:
          return null;
      }
    },
    actionPrimary() {
      return {
        text: i18n.modalAction,
        attributes: { variant: 'danger' },
      };
    },
    actionSecondary() {
      return {
        text: i18n.modalCancel,
        attributes: { variant: 'default' },
      };
    },
  },
  methods: {
    handleModalPrimary() {
      this.resetToken();
    },
    async resetToken() {
      this.loading = true;
      try {
        const {
          data: {
            runnersRegistrationTokenReset: { token, errors },
          },
        } = await this.$apollo.mutate({
          mutation: runnersRegistrationTokenResetMutation,
          variables: {
            input: this.resetTokenInput,
          },
        });
        if (errors && errors.length) {
          throw new Error(errors.join(' '));
        }
        this.onSuccess(token);
      } catch (e) {
        this.onError(e);
      } finally {
        this.loading = false;
      }
    },
    onError(error) {
      const { message } = error;

      createAlert({ message });
      captureException({ error, component: this.$options.name });
    },
    onSuccess(token) {
      this.$toast?.show(s__('Runners|New registration token generated!'));
      this.$emit('tokenReset', token);
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown-item v-gl-modal="$options.modalId">
    <template #list-item>
      {{ __('Reset registration token') }}
      <gl-modal
        size="sm"
        :modal-id="$options.modalId"
        :action-primary="actionPrimary"
        :action-secondary="actionSecondary"
        :title="$options.i18n.modalTitle"
        @primary="handleModalPrimary"
      >
        <p>{{ $options.i18n.modalCopy }}</p>
      </gl-modal>
      <gl-loading-icon v-if="loading" inline />
    </template>
  </gl-disclosure-dropdown-item>
</template>
