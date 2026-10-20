import { GlFormCheckbox } from '@gitlab/ui';
import PolicyEnforcedSetting from './policy_enforced_setting.vue';

const enforcePolicy = {
  name: 'Lock request access',
  webPath: '/groups/my-group/-/security/policy_store/7',
};
const warnPolicy = {
  name: 'Request access review',
  webPath: '/groups/my-group/-/security/policy_store/9',
};

export default {
  component: PolicyEnforcedSetting,
  title: 'vue_shared/settings/policy_enforced_setting',
  argTypes: {
    enforcements: {
      control: 'object',
      description: 'One row per policy governing the setting',
    },
    policyStoreSettingEnforcement: {
      control: 'boolean',
      description: 'State of the policy_store_setting_enforcement feature flag',
    },
  },
};

const Template = (args) => ({
  components: { PolicyEnforcedSetting, GlFormCheckbox },
  provide: {
    glFeatures: { policyStoreSettingEnforcement: args.policyStoreSettingEnforcement },
  },
  setup() {
    return { args };
  },
  template: `
    <div class="gl-p-4">
      <policy-enforced-setting :enforcements="args.enforcements">
        <template #default="{ disabled, describedBy }">
          <gl-form-checkbox :checked="true" :disabled="disabled" :aria-describedby="describedBy">
            Users can request access
          </gl-form-checkbox>
        </template>
      </policy-enforced-setting>
    </div>
  `,
});

export const Enforce = Template.bind({});
Enforce.args = {
  policyStoreSettingEnforcement: true,
  enforcements: [{ mode: 'enforce', policy: enforcePolicy, message: null }],
};

export const Warn = Template.bind({});
Warn.args = {
  policyStoreSettingEnforcement: true,
  enforcements: [
    {
      mode: 'warn',
      policy: warnPolicy,
      message: 'Disable request access before the audit.',
    },
  ],
};

export const SeveralPolicies = Template.bind({});
SeveralPolicies.args = {
  policyStoreSettingEnforcement: true,
  enforcements: [
    { mode: 'warn', policy: warnPolicy, message: null },
    { mode: 'enforce', policy: enforcePolicy, message: null },
  ],
};

export const FlagDisabled = Template.bind({});
FlagDisabled.args = {
  policyStoreSettingEnforcement: false,
  enforcements: Enforce.args.enforcements,
};
