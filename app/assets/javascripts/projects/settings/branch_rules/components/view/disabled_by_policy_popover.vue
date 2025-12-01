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
  i18n: {
    title: s__('BranchRules|Setting blocked by security policy'),
  },
  components: {
    GlPopover,
    GlSprintf,
    GlLink,
    GlIcon,
  },
  inject: ['securityPoliciesPath'],
  computed: {
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
      :aria-label="
        s__(
          'BranchRules|This setting is blocked by a security policy. To make changes, go to the security policies. Learn more.',
        )
      "
    >
      <gl-icon name="lock" variant="disabled" />
    </button>
    <gl-popover triggers="hover focus" :target="triggerId" :title="$options.i18n.title">
      <div>
        <gl-sprintf
          :message="
            s__(
              'BranchRules|This setting is blocked by a security policy. To make changes, go to the %{linkStart}security policies%{linkEnd}. %{learnMoreStart}Learn more.%{learnMoreEnd}',
            )
          "
        >
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
