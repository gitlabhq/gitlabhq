<script>
import {
  GlButton,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlSprintf,
  GlLink,
  GlFormInputGroup,
  GlToastMixin,
} from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import SimpleCopyButton from '~/vue_shared/components/simple_copy_button.vue';

export default {
  i18n: {
    sendEmail: __('Send email'),
    emailNewMergeRequest: __('Email a new merge request to this project'),
    createNewMergeRequestByEmail: __('Create new merge request by email'),
    failedToResetEmail: __('There was an error when resetting email token.'),
    mergeRequestCreationInstruction: __(
      'You can create a new merge request inside this project by sending an email to the following email address:',
    ),
    emailSubjectDescription: __(
      'The subject is used as the title of the new merge request, and the message is the description. %{quickActionsLinkStart}Quick actions%{quickActionsLinkEnd} and styling with %{markdownLinkStart}Markdown%{markdownLinkEnd} are supported.',
    ),
    privateEmailWarning: __(
      'This is a %{emailsHelpLinkStart}private email address%{emailsHelpLinkEnd} generated just for you. Anyone who has it can create merge requests as if they were you. If that happens, %{resetLinkStart}reset this token%{resetLinkEnd}.',
    ),
  },
  name: 'MergeRequestByEmail',
  components: {
    GlButton,
    GlModal,
    GlSprintf,
    GlLink,
    GlFormInputGroup,
    SimpleCopyButton,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [GlToastMixin],
  inject: {
    initialEmail: {
      default: '',
    },
    emailsHelpPagePath: {
      default: '',
    },
    quickActionsHelpPath: {
      default: '',
    },
    markdownHelpPath: {
      default: '',
    },
    resetPath: {
      default: '',
    },
  },
  data() {
    return {
      email: this.initialEmail,
      isResetting: false,
    };
  },
  computed: {
    mailToLink() {
      const subject = __('Enter the merge request title');
      const body = __('Enter the merge request description');
      return `mailto:${this.email}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
    },
  },
  methods: {
    async resetIncomingEmailToken() {
      if (this.isResetting || !this.resetPath) return;

      this.isResetting = true;

      try {
        const {
          data: { new_address: newAddress },
        } = await axios.put(this.resetPath);
        this.email = newAddress;
      } catch (error) {
        this.$toast.show(this.$options.i18n.failedToResetEmail);
        Sentry.captureException(error);
      } finally {
        this.isResetting = false;
      }
    },
    cancelHandler() {
      this.$refs.modal.hide();
    },
  },
  modalId: 'merge-request-email-modal',
};
</script>

<template>
  <div>
    <gl-button
      v-gl-modal="$options.modalId"
      variant="link"
      data-testid="email-merge-request-link"
      data-event-tracking="click_email_merge_request_project_merge_requests_list_page"
    >
      {{ $options.i18n.emailNewMergeRequest }}
    </gl-button>

    <gl-modal ref="modal" :modal-id="$options.modalId">
      <template #modal-title>
        {{ $options.i18n.createNewMergeRequestByEmail }}
      </template>
      <p>
        {{ $options.i18n.mergeRequestCreationInstruction }}
      </p>
      <gl-form-input-group :value="email" readonly select-on-click class="gl-mb-4">
        <template #append>
          <simple-copy-button :text="email" :title="__('Copy')" />
          <gl-button
            v-gl-tooltip.hover
            :href="mailToLink"
            :title="$options.i18n.sendEmail"
            :aria-label="$options.i18n.sendEmail"
            icon="mail"
          />
        </template>
      </gl-form-input-group>
      <p>
        <gl-sprintf :message="$options.i18n.emailSubjectDescription">
          <template #quickActionsLink="{ content }">
            <gl-link :href="quickActionsHelpPath" target="_blank">{{ content }}</gl-link>
          </template>
          <template #markdownLink="{ content }">
            <gl-link :href="markdownHelpPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <p>
        <gl-sprintf :message="$options.i18n.privateEmailWarning">
          <template #emailsHelpLink="{ content }">
            <gl-link :href="emailsHelpPagePath" target="_blank">{{ content }}</gl-link>
          </template>
          <template #resetLink="{ content }">
            <gl-button
              variant="link"
              data-testid="reset_email_token_link"
              :loading="isResetting"
              @click="resetIncomingEmailToken"
            >
              {{ content }}
            </gl-button>
          </template>
        </gl-sprintf>
      </p>
      <template #modal-footer>
        <gl-button category="secondary" @click="cancelHandler">{{ __('Cancel') }}</gl-button>
      </template>
    </gl-modal>
  </div>
</template>
