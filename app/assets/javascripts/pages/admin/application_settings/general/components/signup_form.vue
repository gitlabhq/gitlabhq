<script>
import {
  GlButton,
  GlFormGroup,
  GlFormInput,
  GlFormRadio,
  GlFormRadioGroup,
  GlSprintf,
  GlLink,
  GlModal,
} from '@gitlab/ui';
import { toSafeInteger } from 'lodash';
import csrf from '~/lib/utils/csrf';
import { __, s__, sprintf } from '~/locale';
import SignupCheckbox from './signup_checkbox.vue';

const DENYLIST_TYPE_RAW = 'raw';
const DENYLIST_TYPE_FILE = 'file';

export default {
  csrf,
  DENYLIST_TYPE_RAW,
  DENYLIST_TYPE_FILE,
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormRadio,
    GlFormRadioGroup,
    GlSprintf,
    GlLink,
    SignupCheckbox,
    GlModal,
  },
  inject: [
    'host',
    'settingsPath',
    'signupEnabled',
    'requireAdminApprovalAfterUserSignup',
    'sendUserConfirmationEmail',
    'minimumPasswordLength',
    'minimumPasswordLengthMin',
    'minimumPasswordLengthMax',
    'minimumPasswordLengthHelpLink',
    'domainAllowlistRaw',
    'newUserSignupsCap',
    'domainDenylistEnabled',
    'denylistTypeRawSelected',
    'domainDenylistRaw',
    'emailRestrictionsEnabled',
    'supportedSyntaxLinkUrl',
    'emailRestrictions',
    'afterSignUpText',
  ],
  data() {
    return {
      showModal: false,
      form: {
        signupEnabled: this.signupEnabled,
        requireAdminApproval: this.requireAdminApprovalAfterUserSignup,
        sendConfirmationEmail: this.sendUserConfirmationEmail,
        minimumPasswordLength: this.minimumPasswordLength,
        minimumPasswordLengthMin: this.minimumPasswordLengthMin,
        minimumPasswordLengthMax: this.minimumPasswordLengthMax,
        minimumPasswordLengthHelpLink: this.minimumPasswordLengthHelpLink,
        domainAllowlistRaw: this.domainAllowlistRaw,
        userCap: this.newUserSignupsCap,
        domainDenylistEnabled: this.domainDenylistEnabled,
        denylistType: this.denylistTypeRawSelected
          ? this.$options.DENYLIST_TYPE_RAW
          : this.$options.DENYLIST_TYPE_FILE,
        domainDenylistRaw: this.domainDenylistRaw,
        emailRestrictionsEnabled: this.emailRestrictionsEnabled,
        supportedSyntaxLinkUrl: this.supportedSyntaxLinkUrl,
        emailRestrictions: this.emailRestrictions,
        afterSignUpText: this.afterSignUpText,
      },
    };
  },
  computed: {
    isOldUserCapUnlimited() {
      // User cap is set to unlimited if no value is provided in the field
      return this.newUserSignupsCap === '';
    },
    isNewUserCapUnlimited() {
      // User cap is set to unlimited if no value is provided in the field
      return this.form.userCap === '';
    },
    hasUserCapChangedFromUnlimitedToLimited() {
      return this.isOldUserCapUnlimited && !this.isNewUserCapUnlimited;
    },
    hasUserCapChangedFromLimitedToUnlimited() {
      return !this.isOldUserCapUnlimited && this.isNewUserCapUnlimited;
    },
    hasUserCapBeenIncreased() {
      if (this.hasUserCapChangedFromUnlimitedToLimited) {
        return false;
      }

      const oldValueAsInteger = toSafeInteger(this.newUserSignupsCap);
      const newValueAsInteger = toSafeInteger(this.form.userCap);

      return this.hasUserCapChangedFromLimitedToUnlimited || newValueAsInteger > oldValueAsInteger;
    },
    canUsersBeAccidentallyApproved() {
      const hasUserCapBeenToggledOff =
        this.requireAdminApprovalAfterUserSignup && !this.form.requireAdminApproval;

      return this.hasUserCapBeenIncreased || hasUserCapBeenToggledOff;
    },
    signupEnabledHelpText() {
      const text = sprintf(
        s__(
          'ApplicationSettings|When enabled, any user visiting %{host} will be able to create an account.',
        ),
        {
          host: this.host,
        },
      );

      return text;
    },
    requireAdminApprovalHelpText() {
      const text = sprintf(
        s__(
          'ApplicationSettings|When enabled, any user visiting %{host} and creating an account will have to be explicitly approved by an admin before they can sign in. This setting is effective only if sign-ups are enabled.',
        ),
        {
          host: this.host,
        },
      );

      return text;
    },
  },
  watch: {
    showModal(value) {
      if (value === true) {
        this.$refs[this.$options.modal.id].show();
      } else {
        this.$refs[this.$options.modal.id].hide();
      }
    },
  },
  methods: {
    submitButtonHandler() {
      if (this.canUsersBeAccidentallyApproved) {
        this.showModal = true;

        return;
      }

      this.submitForm();
    },
    submitForm() {
      this.$refs.form.submit();
    },
    modalHideHandler() {
      this.showModal = false;
    },
  },
  i18n: {
    buttonText: s__('ApplicationSettings|Save changes'),
    signupEnabledLabel: s__('ApplicationSettings|Sign-up enabled'),
    requireAdminApprovalLabel: s__('ApplicationSettings|Require admin approval for new sign-ups'),
    sendConfirmationEmailLabel: s__('ApplicationSettings|Send confirmation email on sign-up'),
    minimumPasswordLengthLabel: s__(
      'ApplicationSettings|Minimum password length (number of characters)',
    ),
    domainAllowListLabel: s__('ApplicationSettings|Allowed domains for sign-ups'),
    domainAllowListDescription: s__(
      'ApplicationSettings|ONLY users with e-mail addresses that match these domain(s) will be able to sign-up. Wildcards allowed. Use separate lines for multiple entries. Ex: domain.com, *.domain.com',
    ),
    userCapLabel: s__('ApplicationSettings|User cap'),
    userCapDescription: s__(
      'ApplicationSettings|Once the instance reaches the user cap, any user who is added or requests access will have to be approved by an admin. Leave the field empty for unlimited.',
    ),
    domainDenyListGroupLabel: s__('ApplicationSettings|Domain denylist'),
    domainDenyListLabel: s__('ApplicationSettings|Enable domain denylist for sign ups'),
    domainDenyListTypeFileLabel: s__('ApplicationSettings|Upload denylist file'),
    domainDenyListTypeRawLabel: s__('ApplicationSettings|Enter denylist manually'),
    domainDenyListFileLabel: s__('ApplicationSettings|Denylist file'),
    domainDenyListFileDescription: s__(
      'ApplicationSettings|Users with e-mail addresses that match these domain(s) will NOT be able to sign-up. Wildcards allowed. Use separate lines or commas for multiple entries.',
    ),
    domainDenyListListLabel: s__('ApplicationSettings|Denied domains for sign-ups'),
    domainDenyListListDescription: s__(
      'ApplicationSettings|Users with e-mail addresses that match these domain(s) will NOT be able to sign-up. Wildcards allowed. Use separate lines for multiple entries. Ex: domain.com, *.domain.com',
    ),
    domainPlaceholder: s__('ApplicationSettings|domain.com'),
    emailRestrictionsEnabledGroupLabel: s__('ApplicationSettings|Email restrictions'),
    emailRestrictionsEnabledLabel: s__(
      'ApplicationSettings|Enable email restrictions for sign ups',
    ),
    emailRestrictionsGroupLabel: s__('ApplicationSettings|Email restrictions for sign-ups'),
    afterSignUpTextGroupLabel: s__('ApplicationSettings|After sign up text'),
    afterSignUpTextGroupDescription: s__('ApplicationSettings|Markdown enabled'),
  },
  modal: {
    id: 'signup-settings-modal',
    actionPrimary: {
      text: s__('ApplicationSettings|Approve users'),
      attributes: {
        variant: 'confirm',
      },
    },
    actionCancel: {
      text: __('Cancel'),
    },
    title: s__('ApplicationSettings|Approve all users in the pending approval status?'),
    text: s__(
      'ApplicationSettings|By making this change, you will automatically approve all users in pending approval status.',
    ),
  },
};
</script>

<template>
  <form
    ref="form"
    accept-charset="UTF-8"
    data-testid="form"
    method="post"
    :action="settingsPath"
    enctype="multipart/form-data"
  >
    <input type="hidden" name="utf8" value="✓" />
    <input type="hidden" name="_method" value="patch" />
    <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />

    <section class="gl-mb-8">
      <signup-checkbox
        v-model="form.signupEnabled"
        class="gl-mb-5"
        name="application_setting[signup_enabled]"
        :help-text="signupEnabledHelpText"
        :label="$options.i18n.signupEnabledLabel"
        data-qa-selector="signup_enabled_checkbox"
      />

      <signup-checkbox
        v-model="form.requireAdminApproval"
        class="gl-mb-5"
        name="application_setting[require_admin_approval_after_user_signup]"
        :help-text="requireAdminApprovalHelpText"
        :label="$options.i18n.requireAdminApprovalLabel"
        data-qa-selector="require_admin_approval_after_user_signup_checkbox"
        data-testid="require-admin-approval-checkbox"
      />

      <signup-checkbox
        v-model="form.sendConfirmationEmail"
        class="gl-mb-5"
        name="application_setting[send_user_confirmation_email]"
        :label="$options.i18n.sendConfirmationEmailLabel"
      />

      <gl-form-group
        :label="$options.i18n.userCapLabel"
        :description="$options.i18n.userCapDescription"
      >
        <gl-form-input
          v-model="form.userCap"
          type="text"
          name="application_setting[new_user_signups_cap]"
          data-testid="user-cap-input"
        />
      </gl-form-group>

      <gl-form-group :label="$options.i18n.minimumPasswordLengthLabel">
        <gl-form-input
          v-model="form.minimumPasswordLength"
          :min="form.minimumPasswordLengthMin"
          :max="form.minimumPasswordLengthMax"
          type="number"
          name="application_setting[minimum_password_length]"
        />

        <gl-sprintf
          :message="
            s__(
              'ApplicationSettings|See GitLab\'s %{linkStart}Password Policy Guidelines%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="form.minimumPasswordLengthHelpLink" target="_blank">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </gl-form-group>

      <gl-form-group
        :description="$options.i18n.domainAllowListDescription"
        :label="$options.i18n.domainAllowListLabel"
      >
        <textarea
          v-model="form.domainAllowlistRaw"
          :placeholder="$options.i18n.domainPlaceholder"
          rows="8"
          class="form-control gl-form-input"
          name="application_setting[domain_allowlist_raw]"
        ></textarea>
      </gl-form-group>

      <gl-form-group :label="$options.i18n.domainDenyListGroupLabel">
        <signup-checkbox
          v-model="form.domainDenylistEnabled"
          name="application_setting[domain_denylist_enabled]"
          :label="$options.i18n.domainDenyListLabel"
        />
      </gl-form-group>

      <gl-form-radio-group v-model="form.denylistType" name="denylist_type" class="gl-mb-5">
        <gl-form-radio :value="$options.DENYLIST_TYPE_FILE">{{
          $options.i18n.domainDenyListTypeFileLabel
        }}</gl-form-radio>
        <gl-form-radio :value="$options.DENYLIST_TYPE_RAW">{{
          $options.i18n.domainDenyListTypeRawLabel
        }}</gl-form-radio>
      </gl-form-radio-group>

      <gl-form-group
        v-if="form.denylistType === $options.DENYLIST_TYPE_FILE"
        :description="$options.i18n.domainDenyListFileDescription"
        :label="$options.i18n.domainDenyListFileLabel"
        label-for="domain-denylist-file-input"
        data-testid="domain-denylist-file-input-group"
      >
        <input
          id="domain-denylist-file-input"
          class="form-control gl-form-input"
          type="file"
          accept=".txt,.conf"
          name="application_setting[domain_denylist_file]"
        />
      </gl-form-group>

      <gl-form-group
        v-if="form.denylistType !== $options.DENYLIST_TYPE_FILE"
        :description="$options.i18n.domainDenyListListDescription"
        :label="$options.i18n.domainDenyListListLabel"
        data-testid="domain-denylist-raw-input-group"
      >
        <textarea
          v-model="form.domainDenylistRaw"
          :placeholder="$options.i18n.domainPlaceholder"
          rows="8"
          class="form-control gl-form-input"
          name="application_setting[domain_denylist_raw]"
        ></textarea>
      </gl-form-group>

      <gl-form-group :label="$options.i18n.emailRestrictionsEnabledGroupLabel">
        <signup-checkbox
          v-model="form.emailRestrictionsEnabled"
          name="application_setting[email_restrictions_enabled]"
          :label="$options.i18n.emailRestrictionsEnabledLabel"
        />
      </gl-form-group>

      <gl-form-group :label="$options.i18n.emailRestrictionsGroupLabel">
        <textarea
          v-model="form.emailRestrictions"
          rows="4"
          class="form-control gl-form-input"
          name="application_setting[email_restrictions]"
        ></textarea>

        <gl-sprintf
          :message="
            s__(
              'ApplicationSettings|Restricts sign-ups for email addresses that match the given regex. See the %{linkStart}supported syntax%{linkEnd} for more information.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="form.supportedSyntaxLinkUrl" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </gl-form-group>

      <gl-form-group
        :label="$options.i18n.afterSignUpTextGroupLabel"
        :description="$options.i18n.afterSignUpTextGroupDescription"
      >
        <textarea
          v-model="form.afterSignUpText"
          rows="4"
          class="form-control gl-form-input"
          name="application_setting[after_sign_up_text]"
        ></textarea>
      </gl-form-group>
    </section>

    <gl-button
      data-qa-selector="save_changes_button"
      variant="confirm"
      @click.prevent="submitButtonHandler"
    >
      {{ $options.i18n.buttonText }}
    </gl-button>

    <gl-modal
      :ref="$options.modal.id"
      :modal-id="$options.modal.id"
      :action-cancel="$options.modal.actionCancel"
      :action-primary="$options.modal.actionPrimary"
      :title="$options.modal.title"
      @primary="submitForm"
      @hide="modalHideHandler"
    >
      {{ $options.modal.text }}
    </gl-modal>
  </form>
</template>
