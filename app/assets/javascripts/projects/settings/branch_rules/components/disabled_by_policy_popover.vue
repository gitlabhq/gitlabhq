<script>
import { uniqueId } from 'lodash';
import { GlPopover, GlSprintf, GlLink, GlIcon } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export default {
  name: 'DisabledByPolicyPopover',
  securityPoliciesDocLink: helpPagePath(
    'user/application_security/policies/merge_request_approval_policies',
    { anchor: 'approval_settings' },
  ),
  components: {
    GlPopover,
    GlSprintf,
    GlLink,
    GlIcon,
  },
  inject: ['securityPoliciesPath'],
  props: {
    isProtectedByPolicy: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ariaLabel() {
      return this.isProtectedByPolicy
        ? s__(
            'BranchRules|This setting is blocked by a security policy. To make changes, go to the security policies.',
          )
        : s__(
            'BranchRules|This setting will be blocked if the security policy becomes enforced. To make changes, go to the security policies.',
          );
    },
    iconName() {
      return this.isProtectedByPolicy ? 'lock' : 'warning';
    },
    description() {
      return this.isProtectedByPolicy
        ? s__(
            'BranchRules|This setting is blocked by a security policy. To make changes, go to the %{linkStart}security policies%{linkEnd}. %{learnMoreStart}Learn more.%{learnMoreEnd}',
          )
        : s__(
            'BranchRules|This setting will be blocked if the security policy becomes enforced. To make changes, go to the %{linkStart}security policies%{linkEnd}. %{learnMoreStart}Learn more.%{learnMoreEnd}',
          );
    },
    title() {
      return this.isProtectedByPolicy
        ? s__('BranchRules|Setting blocked by security policy')
        : s__('BranchRules|Setting may be blocked by security policy');
    },
    triggerId() {
      return uniqueId('security-policy-info-');
    },
  },
};
</script>

<template>
  <div>
    <button
      :id="triggerId"
      class="gl-ml-2 gl-border-0 gl-bg-transparent gl-p-2 gl-leading-0"
      :aria-label="ariaLabel"
    >
      <gl-icon :name="iconName" variant="disabled" />
    </button>
    <gl-popover triggers="hover focus" :container="triggerId" :target="triggerId" :title="title">
      <div>
        <gl-sprintf :message="description">
          <template #link="{ content }">
            <gl-link :href="securityPoliciesPath" data-testid="security-policies-path-link">{{
              content
            }}</gl-link>
          </template>
          <template #learnMore="{ content }">
            <gl-link
              :href="$options.securityPoliciesDocLink"
              data-testid="learn-more-link"
              target="_blank"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </div>
    </gl-popover>
  </div>
</template>
