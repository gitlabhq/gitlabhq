<script>
import { get } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlCard, GlDeprecatedButton, GlLoadingIcon } from '@gitlab/ui';
import Tracking from '~/tracking';
import { mapComputed } from '~/vuex_shared/bindings';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '../../shared/constants';
import ExpirationPolicyFields from '../../shared/components/expiration_policy_fields.vue';
import { SET_CLEANUP_POLICY_BUTTON, CLEANUP_POLICY_CARD_HEADER } from '../constants';

export default {
  components: {
    GlCard,
    GlDeprecatedButton,
    GlLoadingIcon,
    ExpirationPolicyFields,
  },
  mixins: [Tracking.mixin()],
  labelsConfig: {
    cols: 3,
    align: 'right',
  },
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
    };
  },
  computed: {
    ...mapState(['formOptions', 'isLoading']),
    ...mapGetters({ isEdited: 'getIsEdited' }),
    ...mapComputed([{ key: 'settings', getter: 'getSettings' }], 'updateSettings'),
    isSubmitButtonDisabled() {
      return !this.fieldsAreValid || this.isLoading;
    },
    isCancelButtonDisabled() {
      return !this.isEdited || this.isLoading;
    },
  },
  methods: {
    ...mapActions(['resetSettings', 'saveSettings']),
    reset() {
      this.track('reset_form');
      this.apiErrors = null;
      this.resetSettings();
    },
    setApiErrors(response) {
      const messages = get(response, 'data.message', []);

      this.apiErrors = Object.keys(messages).reduce((acc, curr) => {
        if (curr.startsWith('container_expiration_policy.')) {
          const key = curr.replace('container_expiration_policy.', '');
          acc[key] = get(messages, [curr, 0], '');
        }
        return acc;
      }, {});
    },
    submit() {
      this.track('submit_form');
      this.apiErrors = null;
      this.saveSettings()
        .then(() => this.$toast.show(UPDATE_SETTINGS_SUCCESS_MESSAGE, { type: 'success' }))
        .catch(({ response }) => {
          this.setApiErrors(response);
          this.$toast.show(UPDATE_SETTINGS_ERROR_MESSAGE, { type: 'error' });
        });
    },
    onModelChange(changePayload) {
      this.settings = changePayload.newValue;
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
          :value="settings"
          :form-options="formOptions"
          :is-loading="isLoading"
          :api-errors="apiErrors"
          @validated="fieldsAreValid = true"
          @invalidated="fieldsAreValid = false"
          @input="onModelChange"
        />
      </template>
      <template #footer>
        <div class="gl-display-flex gl-justify-content-end">
          <gl-deprecated-button
            ref="cancel-button"
            type="reset"
            class="gl-mr-3 gl-display-block"
            :disabled="isCancelButtonDisabled"
          >
            {{ __('Cancel') }}
          </gl-deprecated-button>
          <gl-deprecated-button
            ref="save-button"
            type="submit"
            :disabled="isSubmitButtonDisabled"
            variant="success"
            class="gl-display-flex gl-justify-content-center gl-align-items-center js-no-auto-disable"
          >
            {{ $options.i18n.SET_CLEANUP_POLICY_BUTTON }}
            <gl-loading-icon v-if="isLoading" class="gl-ml-3" />
          </gl-deprecated-button>
        </div>
      </template>
    </gl-card>
  </form>
</template>
