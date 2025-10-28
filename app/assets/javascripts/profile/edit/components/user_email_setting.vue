<script>
import { GlFormGroup, GlFormInput, GlFormSelect, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlLink,
    GlSprintf,
  },
  directives: {
    SafeHtml,
  },
  inject: [
    'emailResendConfirmationLink',
    'isEmailReadonly',
    'emailChangeDisabled',
    'managingGroupName',
    'providerLabel',
    'publicEmailOptions',
    'commitEmailOptions',
  ],
  props: {
    userEmailSettings: {
      type: Object,
      required: true,
    },
    emailHelpText: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    email: {
      get() {
        return this.userEmailSettings.email;
      },
      set(value) {
        this.emitChange({ email: value });
      },
    },
    publicEmail: {
      get() {
        return this.userEmailSettings.publicEmail;
      },
      set(value) {
        this.emitChange({ publicEmail: value });
      },
    },
    commitEmail: {
      get() {
        return this.userEmailSettings.commitEmail;
      },
      set(value) {
        this.emitChange({ commitEmail: value });
      },
    },
    emailHelp() {
      if (this.emailChangeDisabled && this.managingGroupName) {
        return sprintf(
          s__(
            'Profiles|Your account uses dedicated credentials for the "%{groupName}" group and can only be updated through SSO.',
          ),
          {
            groupName: this.managingGroupName,
          },
        );
      }

      if (this.isEmailReadonly && this.providerLabel) {
        return sprintf(
          s__(
            'Profiles|Your email address was automatically set based on your %{providerLabel} account',
          ),
          {
            providerLabel: this.providerLabel,
          },
        );
      }

      return (
        this.emailHelpText ||
        s__('Profiles|We also use email for avatar detection if no avatar is uploaded.')
      );
    },

    isEmailDisabled() {
      return this.isEmailReadonly || this.emailChangeDisabled;
    },
  },

  methods: {
    emitChange(changes) {
      this.$emit('change', {
        ...this.userEmailSettings,
        ...changes,
      });
    },
  },
  commitEmailLinkUrl: helpPagePath('user/profile/_index.md', {
    anchor: 'use-an-automatically-generated-private-commit-email',
  }),
};
</script>

<template>
  <div>
    <gl-form-group :label="s__('Profiles|Email')" data-testid="email-group">
      <gl-form-input v-model="email" width="lg" type="email" required :readonly="isEmailDisabled" />
      <template #description>
        <div v-safe-html="emailHelp" class="[&_p]:!gl-mb-0"></div>
        <div v-if="emailResendConfirmationLink" class="gl-mt-3">
          <gl-link
            :href="emailResendConfirmationLink"
            class="resend-confirmation-email-link"
            data-method="post"
            rel="nofollow"
          >
            {{ s__('Profiles|Resend confirmation email') }}
          </gl-link>
        </div>
      </template>
    </gl-form-group>
    <gl-form-group
      :label="s__('Profiles|Public email')"
      :description="s__('Profiles|This email will be displayed on your public profile.')"
      data-testid="public-email-group"
    >
      <gl-form-select
        v-model="publicEmail"
        width="lg"
        :options="publicEmailOptions"
        :disabled="emailChangeDisabled"
      />
    </gl-form-group>
    <gl-form-group :label="s__('Profiles|Commit email')" data-testid="commit-email-group">
      <gl-form-select
        v-model="commitEmail"
        width="lg"
        :options="commitEmailOptions"
        :disabled="emailChangeDisabled"
      />
      <template #description>
        <div class="gl-mt-3">
          <gl-sprintf
            :message="
              s__(
                'Profiles|This email is used for web-based operations, such as edits and merges. %{linkStart}What is a private commit email?%{linkEnd}',
              )
            "
          >
            <template #link="{ content }">
              <gl-link :href="$options.commitEmailLinkUrl" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </div>
      </template>
    </gl-form-group>
  </div>
</template>
