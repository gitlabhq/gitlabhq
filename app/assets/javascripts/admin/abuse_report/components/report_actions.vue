<script>
import {
  GlForm,
  GlFormGroup,
  GlFormSelect,
  GlFormCheckbox,
  GlFormInput,
  GlButton,
  GlDrawer,
} from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import {
  ACTIONS_I18N,
  NO_ACTION,
  TRUST_ACTION,
  USER_ACTION_OPTIONS,
  REASON_OPTIONS,
  TRUST_REASON,
  STATUS_OPEN,
  SUCCESS_ALERT,
  FAILED_ALERT,
  ERROR_MESSAGE,
} from '../constants';

const formDefaults = {
  user_action: '',
  close: false,
  comment: '',
  reason: '',
};

export default {
  name: 'ReportActions',
  components: {
    GlForm,
    GlFormGroup,
    GlFormSelect,
    GlFormCheckbox,
    GlFormInput,
    GlButton,
    GlDrawer,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    report: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      showActionsDrawer: false,
      validationState: {
        reason: true,
        action: true,
      },
      form: { ...formDefaults },
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    isFormValid() {
      return Object.values(this.validationState).every(Boolean);
    },
    isOpen() {
      return this.report.status === STATUS_OPEN;
    },
    isNotCurrentUser() {
      return this.user.username !== gon.current_username;
    },
    userActionOptions() {
      return this.isNotCurrentUser ? USER_ACTION_OPTIONS : [NO_ACTION];
    },
    reasonOptions() {
      if (!this.isNotCurrentUser) {
        return [];
      }

      if (this.form.user_action === TRUST_ACTION.value) {
        return [TRUST_REASON];
      }
      return REASON_OPTIONS;
    },
  },
  methods: {
    toggleActionsDrawer() {
      this.showActionsDrawer = !this.showActionsDrawer;
    },
    validateReason() {
      this.validationState.reason = Boolean(this.form.reason?.length);
    },
    validateAction() {
      this.validationState.action = Boolean(this.form.user_action?.length) || this.form.close;
    },
    submitForm() {
      this.triggerValidation();

      if (!this.isFormValid) {
        return;
      }

      const { moderateUserPath } = this.report;
      axios.put(moderateUserPath, this.form).then(this.handleResponse).catch(this.handleError);
    },
    handleResponse({ data }) {
      this.toggleActionsDrawer();
      this.$emit('showAlert', SUCCESS_ALERT, data.message);
      if (this.form.close) {
        this.$emit('closeReport');
      }
      this.resetForm();
    },
    handleError({ response }) {
      this.toggleActionsDrawer();
      const message = response?.data?.message || ERROR_MESSAGE;
      this.$emit('showAlert', FAILED_ALERT, message);
    },
    resetForm() {
      this.form = { ...formDefaults };
    },
    triggerValidation() {
      this.validateReason();
      this.validateAction();
    },
  },
  i18n: ACTIONS_I18N,
  DRAWER_Z_INDEX,
};
</script>

<template>
  <div>
    <gl-button class="gl-w-full" data-testid="actions-button" @click="toggleActionsDrawer">
      {{ $options.i18n.actions }}
    </gl-button>
    <gl-drawer
      :open="showActionsDrawer"
      :header-height="getDrawerHeaderHeight"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="toggleActionsDrawer"
    >
      <template #title>
        <div class="gl-text-size-h2 gl-font-bold">{{ $options.i18n.actions }}</div>
      </template>
      <template #default>
        <gl-form @submit.prevent="submitForm">
          <gl-form-group
            data-testid="action"
            :label="$options.i18n.action"
            label-for="action"
            :invalid-feedback="$options.i18n.requiredFieldFeedback"
            :state="validationState.action"
          >
            <gl-form-select
              id="action"
              v-model="form.user_action"
              data-testid="action-select"
              :options="userActionOptions"
              :state="validationState.action"
              @change="validateAction"
            />
          </gl-form-group>
          <gl-form-group v-if="isOpen">
            <gl-form-checkbox v-model="form.close" data-testid="close" @change="validateAction">
              {{ $options.i18n.closeReport }}
            </gl-form-checkbox>
          </gl-form-group>
          <gl-form-group
            data-testid="reason"
            :label="$options.i18n.reason"
            label-for="reason"
            :invalid-feedback="$options.i18n.requiredFieldFeedback"
            :state="validationState.reason"
          >
            <gl-form-select
              id="reason"
              v-model="form.reason"
              data-testid="reason-select"
              :options="reasonOptions"
              :state="validationState.reason"
              @change="validateReason"
            />
          </gl-form-group>
          <gl-form-group
            :optional="true"
            optional-text="(optional)"
            :label="$options.i18n.comment"
            label-for="comment"
          >
            <gl-form-input id="comment" v-model="form.comment" data-testid="comment" />
          </gl-form-group>
        </gl-form>
      </template>
      <template #footer>
        <gl-button
          variant="confirm"
          block
          :disabled="!isFormValid"
          data-testid="submit-button"
          @click="submitForm"
        >
          {{ $options.i18n.confirm }}
        </gl-button>
      </template>
    </gl-drawer>
  </div>
</template>
