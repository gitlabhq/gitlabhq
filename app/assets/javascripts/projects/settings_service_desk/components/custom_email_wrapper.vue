<script>
import { GlAlert, GlLoadingIcon, GlSprintf, GlLink, GlCard } from '@gitlab/ui';
import BetaBadge from '~/vue_shared/components/badges/beta_badge.vue';
import axios from '~/lib/utils/axios_utils';
import {
  FEEDBACK_ISSUE_URL,
  I18N_LOADING_LABEL,
  I18N_CARD_TITLE,
  I18N_GENERIC_ERROR,
  I18N_FEEDBACK_PARAGRAPH,
  I18N_TOAST_SAVED,
  I18N_TOAST_DELETED,
  I18N_TOAST_ENABLED,
  I18N_TOAST_DISABLED,
} from '../custom_email_constants';
import CustomEmailConfirmModal from './custom_email_confirm_modal.vue';
import CustomEmailForm from './custom_email_form.vue';
import CustomEmail from './custom_email.vue';

export default {
  components: {
    BetaBadge,
    GlAlert,
    GlLoadingIcon,
    GlSprintf,
    GlLink,
    GlCard,
    CustomEmailConfirmModal,
    CustomEmailForm,
    CustomEmail,
  },
  FEEDBACK_ISSUE_URL,
  I18N_LOADING_LABEL,
  I18N_CARD_TITLE,
  I18N_FEEDBACK_PARAGRAPH,
  I18N_TOAST_SAVED,
  I18N_TOAST_DELETED,
  props: {
    incomingEmail: {
      type: String,
      required: true,
    },
    customEmailEndpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isLoading: true,
      isSubmitting: false,
      confirmModalVisible: false,
      customEmail: null,
      isEnabled: false,
      verificationState: null,
      verificationError: null,
      smtpAddress: null,
      alertMessage: null,
    };
  },
  computed: {
    customEmailNotSetUp() {
      return !this.isEnabled && this.verificationState === null && this.customEmail === null;
    },
    toastToggleText() {
      return this.isEnabled ? I18N_TOAST_ENABLED : I18N_TOAST_DISABLED;
    },
  },
  mounted() {
    this.getCustomEmailDetails();
  },
  methods: {
    dismissAlert() {
      this.alertMessage = null;
    },
    getCustomEmailDetails() {
      axios
        .get(this.customEmailEndpoint)
        .then(({ data }) => {
          this.updateData(data);
        })
        .catch(this.handleRequestError)
        .finally(() => {
          this.isLoading = false;
          this.enqueueReFetchVerification();
        });
    },
    enqueueReFetchVerification() {
      setTimeout(this.reFetchVerification, 8000);
    },
    reFetchVerification() {
      if (this.verificationState !== 'started') {
        return;
      }
      this.getCustomEmailDetails();
    },
    handleRequestError() {
      this.alertMessage = I18N_GENERIC_ERROR;
    },
    updateData(data) {
      this.customEmail = data.custom_email;
      this.isEnabled = data.custom_email_enabled;
      this.verificationState = data.custom_email_verification_state;
      this.verificationError = data.custom_email_verification_error;
      this.smtpAddress = data.custom_email_smtp_address;
    },
    onSaveCustomEmail(requestData) {
      this.alertMessage = null;
      this.isSubmitting = true;

      axios
        .post(this.customEmailEndpoint, requestData)
        .then(({ data }) => {
          this.updateData(data);
          this.$toast.show(this.$options.I18N_TOAST_SAVED);
          this.enqueueReFetchVerification();
        })
        .catch(this.handleRequestError)
        .finally(() => {
          this.isSubmitting = false;
        });
    },
    onResetCustomEmail() {
      this.confirmModalVisible = true;
    },
    onConfirmModalCanceled() {
      this.confirmModalVisible = false;
    },
    onConfirmModalProceed() {
      this.isSubmitting = true;
      this.confirmModalVisible = false;

      this.deleteCustomEmail();
    },
    deleteCustomEmail() {
      axios
        .delete(this.customEmailEndpoint)
        .then(({ data }) => {
          this.updateData(data);
          this.$toast.show(I18N_TOAST_DELETED);
        })
        .catch(this.handleRequestError)
        .finally(() => {
          this.isSubmitting = false;
        });
    },
    onToggleCustomEmail(isChecked) {
      this.isEnabled = isChecked;
      this.isSubmitting = true;

      const body = {
        custom_email_enabled: this.isEnabled,
      };

      axios
        .put(this.customEmailEndpoint, body)
        .then(({ data }) => {
          this.updateData(data);
          this.$toast.show(this.toastToggleText);
        })
        .catch(this.handleRequestError)
        .finally(() => {
          this.isSubmitting = false;
        });
    },
  },
};
</script>

<template>
  <div class="row gl-mt-7">
    <div class="col-md-9">
      <gl-card>
        <template #header>
          <div class="justify-content-between gl-flex gl-items-center">
            <h5 class="gl-my-0">{{ $options.I18N_CARD_TITLE }}</h5>
            <beta-badge />
          </div>
        </template>

        <template #default>
          <div v-if="isLoading" class="gl-p-3 gl-text-center">
            <gl-loading-icon
              :label="$options.I18N_LOADING_LABEL"
              size="md"
              color="dark"
              variant="spinner"
            />
            {{ $options.I18N_LOADING_LABEL }}
          </div>

          <custom-email-confirm-modal
            :visible="confirmModalVisible"
            :custom-email="customEmail"
            @remove="onConfirmModalProceed"
            @cancel="onConfirmModalCanceled"
          />

          <gl-alert
            v-if="alertMessage"
            variant="warning"
            class="-gl-mx-5 -gl-mt-5 gl-mb-4"
            @dismiss="dismissAlert"
          >
            {{ alertMessage }}
          </gl-alert>

          <!-- Use v-show to preserve form data after verification failure
            without the need to maintain a state in this component. -->
          <custom-email-form
            v-show="customEmailNotSetUp && !isLoading"
            :incoming-email="incomingEmail"
            :is-submitting="isSubmitting"
            @submit="onSaveCustomEmail"
          />

          <custom-email
            v-if="customEmail"
            :incoming-email="incomingEmail"
            :custom-email="customEmail"
            :smtp-address="smtpAddress"
            :verification-state="verificationState"
            :verification-error="verificationError"
            :is-enabled="isEnabled"
            :is-submitting="isSubmitting"
            @toggle="onToggleCustomEmail"
            @reset="onResetCustomEmail"
          />
        </template>

        <template #footer>
          <gl-sprintf :message="$options.I18N_FEEDBACK_PARAGRAPH">
            <template #link="{ content }">
              <gl-link
                :href="$options.FEEDBACK_ISSUE_URL"
                target="_blank"
                data-testid="feedback-link"
                >{{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </template>
      </gl-card>
    </div>
  </div>
</template>
