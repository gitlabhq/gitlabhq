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
import { __, n__, s__, sprintf } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
    PasswordComplexityCheckboxGroup: () =>
      import(
        'ee_component/pages/admin/application_settings/general/components/password_complexity_checkbox_group.vue'
      ),
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'host',
    'settingsPath',
    'signupEnabled',
    'requireAdminApprovalAfterUserSignup',
    'emailConfirmationSetting',
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
    'pendingUserCount',
  ],
  data() {
    return {
      showModal: false,
      form: {
        signupEnabled: this.signupEnabled,
        requireAdminApproval: this.requireAdminApprovalAfterUserSignup,
        emailConfirmationSetting: this.emailConfirmationSetting,
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
      const currentlyPendingUsers = this.pendingUserCount > 0;

      return (this.hasUserCapBeenIncreased || hasUserCapBeenToggledOff) && currentlyPendingUsers;
    },
    signupEnabledHelpText() {
      const text = sprintf(
        s__('ApplicationSettings|Any user that visits %{host} can create an account.'),
        {
          host: this.host,
        },
      );

      return text;
    },
    requireAdminApprovalHelpText() {
      const text = sprintf(
        s__(
          'ApplicationSettings|Any user that visits %{host} and creates an account must be explicitly approved by an administrator before they can sign in. Only effective if sign-ups are enabled.',
        ),
        {
          host: this.host,
        },
      );

      return text;
    },
    approveUsersModal() {
      const { pendingUserCount } = this;

      return {
        id: 'signup-settings-modal',
        text: n__(
          'ApplicationSettings|By making this change, you will automatically approve %d user who is pending approval.',
          'ApplicationSettings|By making this change, you will automatically approve %d users who are pending approval.',
          pendingUserCount,
        ),
        actionPrimary: {
          text: n__(
            'ApplicationSettings|Approve %d user',
            'ApplicationSettings|Approve %d users',
            pendingUserCount,
          ),
          attributes: {
            variant: 'confirm',
          },
        },
        actionCancel: {
          text: __('Cancel'),
        },
        title: s__('ApplicationSettings|Approve users who are pending approval?'),
      };
    },
  },
  watch: {
    showModal(value) {
      if (value === true) {
        this.$refs[this.approveUsersModal.id].show();
      } else {
        this.$refs[this.approveUsersModal.id].hide();
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
    setPasswordComplexity({ name, value }) {
      this.$set(this.form, name, value);
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
    emailConfirmationSettingsLabel: s__('ApplicationSettings|Email confirmation settings'),
    emailConfirmationSettingsOffLabel: s__('ApplicationSettings|Off'),
    emailConfirmationSettingsOffHelpText: s__(
      'ApplicationSettings|New users can sign up without confirming their email address.',
    ),
    emailConfirmationSettingsSoftLabel: s__('ApplicationSettings|Soft'),
    emailConfirmationSettingsSoftHelpText: s__(
      'ApplicationSettings|Send a confirmation email during sign up. New users can log in immediately, but must confirm their email within three days.',
    ),
    emailConfirmationSettingsHardLabel: s__('ApplicationSettings|Hard'),
    emailConfirmationSettingsHardHelpText: s__(
      'ApplicationSettings|Send a confirmation email during sign up. New users must confirm their email address before they can log in.',
    ),
    minimumPasswordLengthLabel: s__(
      'ApplicationSettings|Minimum password length (number of characters)',
    ),
    domainAllowListLabel: s__('ApplicationSettings|Allowed domains for sign-ups'),
    domainAllowListDescription: s__(
      'ApplicationSettings|Only users with e-mail addresses that match these domain(s) can sign up. Wildcards allowed. Use separate lines for multiple entries. Example: domain.com, *.domain.com',
    ),
    userCapLabel: s__('ApplicationSettings|User cap'),
    userCapDescription: s__(
      'ApplicationSettings|After the instance reaches the user cap, any user who is added or requests access must be approved by an administrator. Leave blank for unlimited.',
    ),
    domainDenyListGroupLabel: s__('ApplicationSettings|Domain denylist'),
    domainDenyListLabel: s__('ApplicationSettings|Enable domain denylist for sign-ups'),
    domainDenyListTypeFileLabel: s__('ApplicationSettings|Upload denylist file'),
    domainDenyListTypeRawLabel: s__('ApplicationSettings|Enter denylist manually'),
    domainDenyListFileLabel: s__('ApplicationSettings|Denylist file'),
    domainDenyListFileDescription: s__(
      'ApplicationSettings|Users with e-mail addresses that match these domain(s) cannot sign up. Wildcards allowed. Use separate lines or commas for multiple entries.',
    ),
    domainDenyListListLabel: s__('ApplicationSettings|Denied domains for sign-ups'),
    domainDenyListListDescription: s__(
      'ApplicationSettings|Users with e-mail addresses that match these domain(s) cannot sign up. Wildcards allowed. Use separate lines for multiple entries. Example: domain.com, *.domain.com',
    ),
    domainPlaceholder: s__('ApplicationSettings|domain.com'),
    emailRestrictionsEnabledGroupLabel: s__('ApplicationSettings|Email restrictions'),
    emailRestrictionsEnabledLabel: s__(
      'ApplicationSettings|Enable email restrictions for sign-ups',
    ),
    emailRestrictionsGroupLabel: s__('ApplicationSettings|Email restrictions for sign-ups'),
    afterSignUpTextGroupLabel: s__('ApplicationSettings|After sign-up text'),
    afterSignUpTextGroupDescription: s__(
      'ApplicationSettings|Text shown after a user signs up. Markdown enabled.',
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

      <gl-form-group :label="$options.i18n.emailConfirmationSettingsLabel">
        <gl-form-radio-group
          v-model="form.emailConfirmationSetting"
          name="application_setting[email_confirmation_setting]"
        >
          <gl-form-radio value="off">
            {{ $options.i18n.emailConfirmationSettingsOffLabel }}

            <template #help> {{ $options.i18n.emailConfirmationSettingsOffHelpText }} </template>
          </gl-form-radio>

          <gl-form-radio value="soft">
            {{ $options.i18n.emailConfirmationSettingsSoftLabel }}

            <template #help> {{ $options.i18n.emailConfirmationSettingsSoftHelpText }} </template>
          </gl-form-radio>

          <gl-form-radio value="hard">
            {{ $options.i18n.emailConfirmationSettingsHardLabel }}

            <template #help> {{ $options.i18n.emailConfirmationSettingsHardHelpText }} </template>
          </gl-form-radio>
        </gl-form-radio-group>
      </gl-form-group>

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

        <template #description>
          <gl-sprintf
            :message="
              s__('ApplicationSettings|See %{linkStart}password policy guidelines%{linkEnd}.')
            "
          >
            <template #link="{ content }">
              <gl-link :href="form.minimumPasswordLengthHelpLink" target="_blank">{{
                content
              }}</gl-link>
            </template>
          </gl-sprintf>
        </template>
      </gl-form-group>

      <password-complexity-checkbox-group
        v-if="glFeatures.passwordComplexity"
        @set-password-complexity="setPasswordComplexity"
      />
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

        <template #description>
          <gl-sprintf
            :message="
              s__(
                'ApplicationSettings|Restricts sign-ups for email addresses that match the given regex. %{linkStart}What is the supported syntax?%{linkEnd}',
              )
            "
          >
            <template #link="{ content }">
              <gl-link :href="form.supportedSyntaxLinkUrl" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </template>
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
      :ref="approveUsersModal.id"
      :modal-id="approveUsersModal.id"
      :action-cancel="approveUsersModal.actionCancel"
      :action-primary="approveUsersModal.actionPrimary"
      :title="approveUsersModal.title"
      @primary="submitForm"
      @hide="modalHideHandler"
    >
      {{ approveUsersModal.text }}
    </gl-modal>
  </form>
</template>
