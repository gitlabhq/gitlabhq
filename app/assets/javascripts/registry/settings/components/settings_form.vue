<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlCard, GlButton, GlLoadingIcon } from '@gitlab/ui';
import Tracking from '~/tracking';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '../../shared/constants';
import { mapComputed } from '~/vuex_shared/bindings';
import ExpirationPolicyFields from '../../shared/components/expiration_policy_fields.vue';

export default {
  components: {
    GlCard,
    GlButton,
    GlLoadingIcon,
    ExpirationPolicyFields,
  },
  mixins: [Tracking.mixin()],
  labelsConfig: {
    cols: 3,
    align: 'right',
  },
  data() {
    return {
      tracking: {
        label: 'docker_container_retention_and_expiration_policies',
      },
      formIsValid: true,
    };
  },
  computed: {
    ...mapState(['formOptions', 'isLoading']),
    ...mapGetters({ isEdited: 'getIsEdited' }),
    ...mapComputed([{ key: 'settings', getter: 'getSettings' }], 'updateSettings'),
    isSubmitButtonDisabled() {
      return !this.formIsValid || this.isLoading;
    },
    isCancelButtonDisabled() {
      return !this.isEdited || this.isLoading;
    },
  },
  methods: {
    ...mapActions(['resetSettings', 'saveSettings']),
    reset() {
      this.track('reset_form');
      this.resetSettings();
    },
    submit() {
      this.track('submit_form');
      this.saveSettings()
        .then(() => this.$toast.show(UPDATE_SETTINGS_SUCCESS_MESSAGE, { type: 'success' }))
        .catch(() => this.$toast.show(UPDATE_SETTINGS_ERROR_MESSAGE, { type: 'error' }));
    },
  },
};
</script>

<template>
  <form ref="form-element" @submit.prevent="submit" @reset.prevent="reset">
    <gl-card>
      <template #header>
        {{ s__('ContainerRegistry|Tag expiration policy') }}
      </template>
      <template #default>
        <expiration-policy-fields
          v-model="settings"
          :form-options="formOptions"
          :is-loading="isLoading"
          @validated="formIsValid = true"
          @invalidated="formIsValid = false"
        />
      </template>
      <template #footer>
        <div class="d-flex justify-content-end">
          <gl-button
            ref="cancel-button"
            type="reset"
            class="mr-2 d-block"
            :disabled="isCancelButtonDisabled"
          >
            {{ __('Cancel') }}
          </gl-button>
          <gl-button
            ref="save-button"
            type="submit"
            :disabled="isSubmitButtonDisabled"
            variant="success"
            class="d-flex justify-content-center align-items-center js-no-auto-disable"
          >
            {{ __('Save expiration policy') }}
            <gl-loading-icon v-if="isLoading" class="ml-2" />
          </gl-button>
        </div>
      </template>
    </gl-card>
  </form>
</template>
