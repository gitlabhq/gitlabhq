<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import getUserPersonalAccessTokens from '../graphql/get_user_personal_access_tokens.query.graphql';
import getUserPersonalAccessTokenStatistics from '../graphql/get_user_personal_access_token_statistics.query.graphql';
import revokePersonalAccessToken from '../graphql/revoke_personal_access_token.mutation.graphql';
import rotatePersonalAccessToken from '../graphql/rotate_personal_access_token.mutation.graphql';
import { ACTIONS } from '../constants';

export default {
  name: 'PersonalAccessTokenActions',
  components: {
    GlModal,
    GlSprintf,
  },
  props: {
    token: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    action: {
      type: String,
      required: false,
      default: null,
    },
  },
  emits: ['close', 'rotated', 'revoked'],
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    isModalVisible() {
      return Boolean(this.token);
    },
    modalTitle() {
      if (!this.action) {
        return '';
      }

      return sprintf(
        this.$options.i18n.modal.title[this.action],
        {
          tokenName: this.token?.name,
        },
        false,
      );
    },
    modalDescription() {
      if (!this.action) {
        return '';
      }

      return this.$options.i18n.modal.description[this.action];
    },
    actionPrimary() {
      if (!this.action) {
        return {};
      }

      return {
        text: this.$options.i18n.modal.button[this.action],
        attributes: {
          variant: this.action === ACTIONS.REVOKE ? 'danger' : 'confirm',
          loading: this.isLoading,
        },
      };
    },
  },
  methods: {
    handleModalHide() {
      this.isLoading = false;
      this.$emit('close');
    },
    handleModalPrimary() {
      this.isLoading = true;

      if (this.action === ACTIONS.REVOKE) {
        this.revokeToken();
      } else if (this.action === ACTIONS.ROTATE) {
        this.rotateToken();
      }
    },
    rotateToken() {
      this.$apollo
        .mutate({
          mutation: rotatePersonalAccessToken,
          variables: {
            id: this.token.id,
          },
          refetchQueries: [getUserPersonalAccessTokens],
          update: (_, { data: { personalAccessTokenRotate } }) => {
            const { token, errors } = personalAccessTokenRotate;

            if (errors?.length) {
              throw Error(errors.join(','));
            }

            this.$emit('rotated', token);
          },
        })
        .catch((error) => {
          createAlert({
            message: this.$options.i18n.error[this.action],
            captureError: true,
            error,
          });
        })
        .finally(() => {
          this.isLoading = false;
          this.handleModalHide();
        });
    },
    revokeToken() {
      this.$apollo
        .mutate({
          mutation: revokePersonalAccessToken,
          variables: {
            id: this.token.id,
          },
          refetchQueries: [getUserPersonalAccessTokens, getUserPersonalAccessTokenStatistics],
          update: (_, { data: { personalAccessTokenRevoke } }) => {
            const { errors } = personalAccessTokenRevoke;

            if (errors?.length) {
              throw Error(errors.join(','));
            }

            this.$emit('revoked');

            createAlert({
              message: sprintf(this.$options.i18n.success[this.action], {
                tokenName: this.token.name,
              }),
              variant: VARIANT_SUCCESS,
            });
          },
        })
        .catch((error) => {
          createAlert({
            message: this.$options.i18n.error[this.action],
            captureError: true,
            error,
          });
        })
        .finally(() => {
          this.isLoading = false;
          this.handleModalHide();
        });
    },
  },
  i18n: {
    modal: {
      title: {
        [ACTIONS.REVOKE]: s__("AccessTokens|Revoke the token '%{tokenName}'?"),
        [ACTIONS.ROTATE]: s__("AccessTokens|Rotate the token '%{tokenName}'?"),
      },
      description: {
        [ACTIONS.REVOKE]: s__(
          'AccessTokens|Are you sure you want to revoke the token %{tokenName}? This action cannot be undone. Any tools that rely on this token will no longer have access to GitLab.',
        ),
        [ACTIONS.ROTATE]: s__(
          'AccessTokens|Are you sure you want to rotate the token %{tokenName}? This action cannot be undone. Any tools that rely on this token will no longer have access to GitLab.',
        ),
      },
      button: {
        [ACTIONS.REVOKE]: s__('AccessTokens|Revoke'),
        [ACTIONS.ROTATE]: s__('AccessTokens|Rotate'),
      },
      actionCancel: {
        text: __('Cancel'),
      },
    },
    success: {
      [ACTIONS.REVOKE]: s__('AccessTokens|The token was revoked successfully.'),
      [ACTIONS.ROTATE]: s__('AccessTokens|The token was rotated successfully.'),
    },
    error: {
      [ACTIONS.REVOKE]: s__('AccessTokens|Token revocation unsuccessful. Please try again.'),
      [ACTIONS.ROTATE]: s__('AccessTokens|Token rotation unsuccessful. Please try again.'),
    },
  },
};
</script>

<template>
  <gl-modal
    :visible="isModalVisible"
    :title="modalTitle"
    :action-cancel="$options.i18n.modal.actionCancel"
    :action-primary="actionPrimary"
    modal-id="token-action-modal"
    @canceled="handleModalHide"
    @hidden="handleModalHide"
    @primary.prevent="handleModalPrimary"
  >
    <gl-sprintf :message="modalDescription">
      <template #tokenName
        ><strong>{{ token && token.name }}</strong></template
      >
    </gl-sprintf>
  </gl-modal>
</template>
