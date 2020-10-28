<script>
import { GlCard, GlButton } from '@gitlab/ui';
import Tracking from '~/tracking';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '../../shared/constants';
import ExpirationPolicyFields from '../../shared/components/expiration_policy_fields.vue';
import { SET_CLEANUP_POLICY_BUTTON, CLEANUP_POLICY_CARD_HEADER } from '../constants';
import { formOptionsGenerator } from '~/registry/shared/utils';
import updateContainerExpirationPolicyMutation from '../graphql/mutations/update_container_expiration_policy.graphql';
import { updateContainerExpirationPolicy } from '../graphql/utils/cache_update';

export default {
  components: {
    GlCard,
    GlButton,
    ExpirationPolicyFields,
  },
  mixins: [Tracking.mixin()],
  inject: ['projectPath'],
  props: {
    value: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEdited: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  labelsConfig: {
    cols: 3,
    align: 'right',
  },
  formOptions: formOptionsGenerator(),
  i18n: {
    CLEANUP_POLICY_CARD_HEADER,
    SET_CLEANUP_POLICY_BUTTON,
  },
  data() {
    return {
      tracking: {
        label: 'docker_container_retention_and_expiration_policies',
      },
      fieldsAreValid: true,
      apiErrors: null,
      mutationLoading: false,
    };
  },
  computed: {
    prefilledForm() {
      return {
        ...this.value,
        cadence: this.findDefaultOption('cadence'),
        keepN: this.findDefaultOption('keepN'),
        olderThan: this.findDefaultOption('olderThan'),
      };
    },
    showLoadingIcon() {
      return this.isLoading || this.mutationLoading;
    },
    isSubmitButtonDisabled() {
      return !this.fieldsAreValid || this.showLoadingIcon;
    },
    isCancelButtonDisabled() {
      return !this.isEdited || this.isLoading || this.mutationLoading;
    },
    mutationVariables() {
      return {
        projectPath: this.projectPath,
        enabled: this.value.enabled,
        cadence: this.value.cadence,
        olderThan: this.value.olderThan,
        keepN: this.value.keepN,
        nameRegex: this.value.nameRegex,
        nameRegexKeep: this.value.nameRegexKeep,
      };
    },
  },
  methods: {
    findDefaultOption(option) {
      return this.value[option] || this.$options.formOptions[option].find(f => f.default)?.key;
    },
    reset() {
      this.track('reset_form');
      this.apiErrors = null;
      this.$emit('reset');
    },
    setApiErrors(response) {
      this.apiErrors = response.graphQLErrors.reduce((acc, curr) => {
        curr.extensions.problems.forEach(item => {
          acc[item.path[0]] = item.message;
        });
        return acc;
      }, {});
    },
    submit() {
      this.track('submit_form');
      this.apiErrors = null;
      this.mutationLoading = true;
      return this.$apollo
        .mutate({
          mutation: updateContainerExpirationPolicyMutation,
          variables: {
            input: this.mutationVariables,
          },
          update: updateContainerExpirationPolicy(this.projectPath),
        })
        .then(({ data }) => {
          const errorMessage = data?.updateContainerExpirationPolicy?.errors[0];
          if (errorMessage) {
            this.$toast.show(errorMessage, { type: 'error' });
          } else {
            this.$toast.show(UPDATE_SETTINGS_SUCCESS_MESSAGE, { type: 'success' });
          }
        })
        .catch(error => {
          this.setApiErrors(error);
          this.$toast.show(UPDATE_SETTINGS_ERROR_MESSAGE, { type: 'error' });
        })
        .finally(() => {
          this.mutationLoading = false;
        });
    },
    onModelChange(changePayload) {
      this.$emit('input', changePayload.newValue);
      if (this.apiErrors) {
        this.apiErrors[changePayload.modified] = undefined;
      }
    },
  },
};
</script>

<template>
  <form ref="form-element" @submit.prevent="submit" @reset.prevent="reset">
    <gl-card>
      <template #header>
        {{ $options.i18n.CLEANUP_POLICY_CARD_HEADER }}
      </template>
      <template #default>
        <expiration-policy-fields
          :value="prefilledForm"
          :form-options="$options.formOptions"
          :is-loading="isLoading"
          :api-errors="apiErrors"
          @validated="fieldsAreValid = true"
          @invalidated="fieldsAreValid = false"
          @input="onModelChange"
        />
      </template>
      <template #footer>
        <gl-button
          ref="cancel-button"
          type="reset"
          class="gl-mr-3 gl-display-block float-right"
          :disabled="isCancelButtonDisabled"
        >
          {{ __('Cancel') }}
        </gl-button>
        <gl-button
          ref="save-button"
          type="submit"
          :disabled="isSubmitButtonDisabled"
          :loading="showLoadingIcon"
          variant="success"
          category="primary"
          class="js-no-auto-disable"
        >
          {{ $options.i18n.SET_CLEANUP_POLICY_BUTTON }}
        </gl-button>
      </template>
    </gl-card>
  </form>
</template>
