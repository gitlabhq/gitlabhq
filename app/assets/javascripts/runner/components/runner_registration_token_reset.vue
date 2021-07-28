<script>
import { GlButton } from '@gitlab/ui';
import createFlash, { FLASH_TYPES } from '~/flash';
import { TYPE_GROUP, TYPE_PROJECT } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import runnersRegistrationTokenResetMutation from '~/runner/graphql/runners_registration_token_reset.mutation.graphql';
import { captureException } from '~/runner/sentry_utils';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '../constants';

export default {
  name: 'RunnerRegistrationTokenReset',
  components: {
    GlButton,
  },
  inject: {
    groupId: {
      default: null,
    },
    projectId: {
      default: null,
    },
  },
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
    async resetToken() {
      // TODO Replace confirmation with gl-modal
      // See: https://gitlab.com/gitlab-org/gitlab/-/issues/333810
      // eslint-disable-next-line no-alert
      if (!window.confirm(__('Are you sure you want to reset the registration token?'))) {
        return;
      }

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
      createFlash({ message });

      this.reportToSentry(error);
    },
    onSuccess(token) {
      createFlash({
        message: s__('Runners|New registration token generated!'),
        type: FLASH_TYPES.SUCCESS,
      });
      this.$emit('tokenReset', token);
    },
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
  },
};
</script>
<template>
  <gl-button :loading="loading" @click="resetToken">
    {{ __('Reset registration token') }}
  </gl-button>
</template>
