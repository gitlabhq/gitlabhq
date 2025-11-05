<script>
import {
  GlButton,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlSprintf,
  GlLink,
  GlFormInputGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import namespaceRegenerateNewWorkItemEmailAddressMutation from '../graphql/namespace_regenerate_new_work_item_email_address.mutation.graphql';

export default {
  i18n: {
    sendEmail: s__('WorkItem|Send email'),
    emailNewWorkItem: { text: s__('WorkItem|Email work item to this project') },
    createNewWorkItemByEmail: s__('WorkItem|Create new work item by email'),
    failedToRegenerateEmail: s__('WorkItem|There was an error when resetting email token.'),
    workItemCreationInstruction: s__(
      'WorkItem|You can create a new work item inside this project by sending an email to the following email address:',
    ),
    emailSubjectDescription: s__(
      'WorkItem|The subject is used as the title of the new work item, and the message is the description. %{quickActionsLinkStart}Quick actions%{quickActionsLinkEnd} and styling with %{markdownLinkStart}Markdown%{markdownLinkEnd} are supported.',
    ),
    privateEmailWarning: s__(
      'WorkItem|This is a %{emailsHelpLinkStart}private email address%{emailsHelpLinkEnd} generated just for you. Anyone who has it can create work items as if they were you. If that happens, %{resetLinkStart}reset this token%{resetLinkEnd}.',
    ),
  },
  name: 'WorkItemByEmail',
  components: {
    GlButton,
    GlModal,
    GlSprintf,
    GlLink,
    GlFormInputGroup,
    ModalCopyButton,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    newWorkItemEmailAddress: {
      default: null,
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
    fullPath: {
      default: '',
    },
  },
  data() {
    return {
      email: this.newWorkItemEmailAddress,
      isRegenerating: false,
    };
  },
  computed: {
    mailToLink() {
      const subject = sprintf(s__('WorkItem|Enter the work item title'));
      const body = sprintf(s__('WorkItem|Enter the work item description'));
      return `mailto:${this.email}?subject=${subject}&body=${body}`;
    },
  },
  methods: {
    async regenerateIncomingEmailToken() {
      if (this.isRegenerating) return;

      this.isRegenerating = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: namespaceRegenerateNewWorkItemEmailAddressMutation,
          variables: {
            fullPath: this.fullPath,
          },
        });

        if (data.namespacesRegenerateNewWorkItemEmailAddress?.errors?.length > 0) {
          throw new Error(data.namespacesRegenerateNewWorkItemEmailAddress.errors[0]);
        }

        const newEmail =
          data.namespacesRegenerateNewWorkItemEmailAddress?.namespace?.linkPaths
            ?.newWorkItemEmailAddress;
        if (newEmail) {
          this.email = newEmail;
        }
      } catch {
        this.$toast.show(this.$options.i18n.failedToRegenerateEmail);
      } finally {
        this.isRegenerating = false;
      }
    },
    cancelHandler() {
      this.$refs.modal.hide();
    },
  },
  modalId: 'work-item-email-modal',
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown-item
      v-gl-modal="$options.modalId"
      :item="$options.i18n.emailNewWorkItem"
    />

    <gl-modal ref="modal" :modal-id="$options.modalId">
      <template #modal-title>
        {{ $options.i18n.createNewWorkItemByEmail }}
      </template>
      <p>
        {{ $options.i18n.workItemCreationInstruction }}
      </p>
      <gl-form-input-group :value="email" readonly select-on-click class="gl-mb-4">
        <template #append>
          <modal-copy-button :text="email" :title="__('Copy')" :modal-id="$options.modalId" />
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
              :loading="isRegenerating"
              @click="regenerateIncomingEmailToken"
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
