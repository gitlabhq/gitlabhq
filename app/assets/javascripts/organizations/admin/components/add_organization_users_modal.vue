<script>
import { GlModal, GlFormGroup, GlFormSelect, GlAlert, GlSprintf, GlToastMixin } from '@gitlab/ui';
import { isUserEmail } from '~/lib/utils/forms';
import { s__, sprintf } from '~/locale';
import { memberName } from '~/invite_members/utils/member_utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import organizationUserCreateMutation from '../graphql/mutations/organization_user_create.mutation.graphql';
import { ORGANIZATION_USER_TYPE_DEFAULT, ORGANIZATION_USER_TYPE_OPTIONS } from '../constants';
import OrganizationUsersTokenSelect from './organization_users_token_select.vue';

export default {
  name: 'AddOrganizationUsersModal',
  components: {
    GlModal,
    GlFormGroup,
    GlFormSelect,
    GlAlert,
    GlSprintf,
    OrganizationUsersTokenSelect,
  },
  mixins: [GlToastMixin],
  inject: ['organizationGid', 'organizationName'],
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['change'],
  data() {
    return {
      selectedTokens: [],
      selectedUserType: ORGANIZATION_USER_TYPE_DEFAULT,
      submitting: false,
      errorMessages: [],
      invitedCount: 0,
      attemptedCount: 0,
    };
  },
  computed: {
    modalDescription() {
      return sprintf(
        s__(
          "Organization|You're inviting users to the %{strongStart}%{name}%{strongEnd} organization.",
        ),
        { name: this.organizationName },
      );
    },
    isSubmitDisabled() {
      return this.submitting || this.selectedTokens.length === 0;
    },
    hasErrors() {
      return this.errorMessages.length > 0;
    },
    isPartialSuccess() {
      return this.invitedCount > 0;
    },
    alertVariant() {
      return this.isPartialSuccess ? 'warning' : 'danger';
    },
    alertTitle() {
      if (this.isPartialSuccess) {
        return sprintf(s__('Organization|%{invited} of %{total} users invited.'), {
          invited: this.invitedCount,
          total: this.attemptedCount,
        });
      }

      return s__('Organization|The following users could not be invited:');
    },
    actionPrimary() {
      return {
        text: s__('Organization|Invite'),
        attributes: {
          variant: 'confirm',
          loading: this.submitting,
          disabled: this.isSubmitDisabled,
        },
      };
    },
    actionCancel() {
      return { text: s__('Organization|Cancel') };
    },
  },
  methods: {
    onTokensInput(tokens) {
      this.selectedTokens = tokens;
    },
    tokenToVariables(token) {
      // Existing users carry a username; user-defined tokens carry an email in `name`.
      const identifier = token.username
        ? { username: token.username }
        : isUserEmail(token.name) && { email: token.name };

      if (!identifier) {
        return null;
      }

      return {
        organizationId: this.organizationGid,
        userType: this.selectedUserType,
        ...identifier,
      };
    },
    async addUser(variables) {
      const { data } = await this.$apollo.mutate({
        mutation: organizationUserCreateMutation,
        variables: { input: variables },
        // Each user is a separate request; caching a null organizationUser makes
        // concurrent failures normalize to the same cache entry and clobber each other.
        fetchPolicy: 'no-cache',
      });

      return data?.organizationUserCreate?.errors ?? [];
    },
    inviteToken(token) {
      const variables = this.tokenToVariables(token);

      if (variables === null) {
        const validationError = new Error(
          s__('Organization|Enter an email address or GitLab username.'),
        );
        validationError.isValidationError = true;
        return Promise.reject(validationError);
      }

      return this.addUser(variables);
    },
    collectResults(tokens, results) {
      const errors = [];
      const succeededTokens = [];

      results.forEach((result, index) => {
        const token = tokens[index];
        const name = token.name || memberName(token);

        if (result.status === 'rejected') {
          if (!result.reason?.isValidationError) {
            Sentry.captureException(result.reason);
          }

          errors.push({
            name,
            message:
              result.reason?.message ||
              s__(
                'Organization|An error occurred while adding users to the organization. Please try again.',
              ),
          });
        } else if (result.value.length) {
          errors.push(...result.value.map((message) => ({ name, message })));
        } else {
          succeededTokens.push(token);
        }
      });

      return { errors, succeededTokens };
    },
    async onPrimary(event) {
      event.preventDefault();

      this.submitting = true;
      this.dismissAlert();

      // Snapshot the tokens so results map back to the right ones even if
      // selectedTokens changes while the requests are in flight.
      const tokens = this.selectedTokens;

      // Fire every invite in parallel and wait for all of them to settle before
      // showing the aggregated response.
      const results = await Promise.allSettled(tokens.map((token) => this.inviteToken(token)));

      this.submitting = false;

      const { errors, succeededTokens } = this.collectResults(tokens, results);

      // Keep only the users that failed so a resubmit does not re-add the ones that succeeded.
      this.selectedTokens = this.selectedTokens.filter((token) => !succeededTokens.includes(token));

      if (errors.length) {
        this.invitedCount = succeededTokens.length;
        this.attemptedCount = results.length;
        this.errorMessages = errors;
        return;
      }

      this.$toast.show(s__('Organization|Users were successfully added to the organization.'));
      this.reset();
      this.$emit('change', false);
    },
    onCancel() {
      this.reset();
      this.$emit('change', false);
    },
    onChange(value) {
      this.$emit('change', value);
    },
    dismissAlert() {
      this.errorMessages = [];
      this.invitedCount = 0;
      this.attemptedCount = 0;
    },
    reset() {
      this.selectedTokens = [];
      this.selectedUserType = ORGANIZATION_USER_TYPE_DEFAULT;
      this.dismissAlert();
    },
  },
  userTypeOptions: ORGANIZATION_USER_TYPE_OPTIONS,
  modalId: 'add-organization-users-modal',
};
</script>

<template>
  <gl-modal
    :modal-id="$options.modalId"
    :visible="visible"
    :title="s__('Organization|Invite organization user')"
    size="sm"
    dialog-class="gl-mx-5"
    :action-primary="actionPrimary"
    :action-cancel="actionCancel"
    @primary="onPrimary"
    @canceled="onCancel"
    @change="onChange"
  >
    <p data-testid="modal-description">
      <gl-sprintf :message="modalDescription">
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
      </gl-sprintf>
    </p>

    <gl-alert
      v-if="hasErrors"
      :variant="alertVariant"
      :title="alertTitle"
      class="gl-mb-4"
      data-testid="add-users-error-alert"
      @dismiss="dismissAlert"
    >
      <ul class="gl-mb-0 gl-pl-5">
        <li v-for="(error, index) in errorMessages" :key="index">
          <gl-sprintf :message="s__('Organization|%{name}: %{message}')">
            <template #name>
              <strong>{{ error.name }}</strong>
            </template>
            <template #message>{{ error.message }}</template>
          </gl-sprintf>
        </li>
      </ul>
    </gl-alert>

    <gl-form-group
      :label="s__('Organization|Email addresses or GitLab usernames')"
      label-for="organization-users-token-select"
    >
      <organization-users-token-select
        input-id="organization-users-token-select"
        :selected-tokens="selectedTokens"
        @input="onTokensInput"
      />
    </gl-form-group>

    <gl-form-group :label="s__('Organization|User type')" label-for="organization-users-role">
      <gl-form-select
        id="organization-users-role"
        v-model="selectedUserType"
        :options="$options.userTypeOptions"
        data-testid="organization-users-role-select"
      />
    </gl-form-group>
  </gl-modal>
</template>
