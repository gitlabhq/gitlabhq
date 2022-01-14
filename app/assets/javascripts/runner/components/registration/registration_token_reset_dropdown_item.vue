<script>
import { GlDropdownItem, GlLoadingIcon, GlModal, GlModalDirective } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { TYPE_GROUP, TYPE_PROJECT } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import runnersRegistrationTokenResetMutation from '~/runner/graphql/runners_registration_token_reset.mutation.graphql';
import { captureException } from '~/runner/sentry_utils';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '../../constants';

export default {
  name: 'RunnerRegistrationTokenReset',
  i18n: {
    modalTitle: __('Reset registration token'),
    modalCopy: __('Are you sure you want to reset the registration token?'),
  },
  components: {
    GlDropdownItem,
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
  modalID: 'token-reset-modal',
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
            id: convertToGraphQLId(TYPE_GROUP, this.groupId),
            type: this.type,
          };
        case PROJECT_TYPE:
          return {
            id: convertToGraphQLId(TYPE_PROJECT, this.projectId),
            type: this.type,
          };
        default:
          return null;
      }
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

      this.reportToSentry(error);
    },
    onSuccess(token) {
      this.$toast?.show(s__('Runners|New registration token generated!'));
      this.$emit('tokenReset', token);
    },
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
  },
};
</script>
<template>
  <gl-dropdown-item v-gl-modal="$options.modalID">
    {{ __('Reset registration token') }}
    <gl-modal
      :modal-id="$options.modalID"
      :title="$options.i18n.modalTitle"
      @primary="handleModalPrimary"
    >
      <p>{{ $options.i18n.modalCopy }}</p>
    </gl-modal>
    <gl-loading-icon v-if="loading" inline />
  </gl-dropdown-item>
</template>
