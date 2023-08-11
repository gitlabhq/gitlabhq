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
} from '../custom_email_constants';
import CustomEmailConfirmModal from './custom_email_confirm_modal.vue';
import CustomEmailForm from './custom_email_form.vue';
import CustomEmailStateStarted from './custom_email_state_started.vue';

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
    CustomEmailStateStarted,
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
      default: '',
    },
    customEmailEndpoint: {
      type: String,
      required: true,
      default: '',
    },
  },
  data() {
    return {
      loading: true,
      submitting: false,
      confirmModalVisible: false,
      customEmail: null,
      enabled: false,
      verificationState: null,
      verificationError: null,
      smtpAddress: null,
      errorMessage: null,
      alertMessage: null,
    };
  },
  computed: {
    customEmailNotSetUp() {
      return !this.enabled && this.verificationState === null && this.customEmail === null;
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
          this.loading = false;
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
      this.enabled = data.custom_email_enabled;
      this.verificationState = data.custom_email_verification_state;
      this.verificationError = data.custom_email_verification_error;
      this.smtpAddress = data.custom_email_smtp_address;
      this.errorMessage = data.error_message;
    },
    onSaveCustomEmail(requestData) {
      this.alertMessage = null;
      this.submitting = true;

      axios
        .post(this.customEmailEndpoint, requestData)
        .then(({ data }) => {
          this.updateData(data);
          this.$toast.show(this.$options.I18N_TOAST_SAVED);
          this.enqueueReFetchVerification();
        })
        .catch(this.handleRequestError)
        .finally(() => {
          this.submitting = false;
        });
    },
    onResetCustomEmail() {
      this.confirmModalVisible = true;
    },
    onConfirmModalCanceled() {
      this.confirmModalVisible = false;
    },
    onConfirmModalProceed() {
      this.submitting = true;
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
          this.submitting = false;
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
          <div class="gl-display-flex align-items-center justify-content-between">
            <h5 class="gl-my-0">{{ $options.I18N_CARD_TITLE }}</h5>
            <beta-badge />
          </div>
        </template>

        <template #default>
          <template v-if="loading">
            <div class="gl-p-3 gl-text-center">
              <gl-loading-icon
                :label="$options.I18N_LOADING_LABEL"
                size="md"
                color="dark"
                variant="spinner"
                :inline="false"
              />
              {{ $options.I18N_LOADING_LABEL }}
            </div>
          </template>

          <custom-email-confirm-modal
            :visible="confirmModalVisible"
            :custom-email="customEmail"
            @remove="onConfirmModalProceed"
            @cancel="onConfirmModalCanceled"
          />

          <gl-alert
            v-if="alertMessage"
            variant="warning"
            class="gl-mt-n5 gl-mb-4 gl-mx-n5"
            @dismiss="dismissAlert"
          >
            {{ alertMessage }}
          </gl-alert>

          <!-- Use v-show to preserve form data after verification failure
            without the need to maintain a state in this component. -->
          <custom-email-form
            v-show="customEmailNotSetUp && !loading"
            :incoming-email="incomingEmail"
            :submitting="submitting"
            @submit="onSaveCustomEmail"
          />

          <custom-email-state-started
            v-if="verificationState === 'started'"
            :custom-email="customEmail"
            :smtp-address="smtpAddress"
            :submitting="submitting"
            @reset="onResetCustomEmail"
          />
        </template>

        <template #footer>
          <span>
            <gl-sprintf :message="$options.I18N_FEEDBACK_PARAGRAPH">
              <template #link="{ content }">
                <gl-link
                  :href="$options.FEEDBACK_ISSUE_URL"
                  data-testid="feedback-link"
                  target="_blank"
                  class="gl-text-blue-600 font-size-inherit"
                  >{{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </span>
        </template>
      </gl-card>
    </div>
  </div>
</template>
