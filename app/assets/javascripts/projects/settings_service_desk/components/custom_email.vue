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
} from '../custom_email_constants';

export default {
  components: {
    BetaBadge,
    GlAlert,
    GlLoadingIcon,
    GlSprintf,
    GlLink,
    GlCard,
  },
  FEEDBACK_ISSUE_URL,
  I18N_LOADING_LABEL,
  I18N_CARD_TITLE,
  I18N_FEEDBACK_PARAGRAPH,
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
      customEmail: null,
      enabled: false,
      verificationState: null,
      verificationError: null,
      smtpAddress: null,
      errorMessage: null,
      alertMessage: null,
    };
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
        });
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

          <gl-alert
            v-if="alertMessage"
            variant="warning"
            class="gl-mt-n5 gl-mx-n5"
            @dismiss="dismissAlert"
          >
            {{ alertMessage }}
          </gl-alert>
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
