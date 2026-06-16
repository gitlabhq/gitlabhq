<script>
import { GlBanner } from '@gitlab/ui';
import AddUserSvg from '@gitlab/svgs/dist/illustrations/add-user-sm.svg?url';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';

export default {
  name: 'SecurityManagerRoleBanner',
  components: {
    GlBanner,
    UserCalloutDismisser,
  },
  i18n: {
    title: s__('MemberRole|New Security Manager role now available'),
    body: s__(
      'MemberRole|The Security Manager role provides comprehensive access to security features, including vulnerability management, security dashboards, policy configuration, and compliance tools. Use this role for users who manage security and compliance across your organization.',
    ),
    buttonText: s__('MemberRole|Learn more'),
    dismissLabel: __('Dismiss'),
  },
  buttonAttributes: {
    target: '_blank',
  },
  AddUserSvg,
  helpPath: helpPagePath('user/permissions'),
};
</script>

<template>
  <user-callout-dismisser feature-name="security_manager_role">
    <template #default="{ shouldShowCallout, dismiss }">
      <gl-banner
        v-if="shouldShowCallout"
        :title="$options.i18n.title"
        :button-text="$options.i18n.buttonText"
        :button-link="$options.helpPath"
        :button-attributes="$options.buttonAttributes"
        :dismiss-label="$options.i18n.dismissLabel"
        :svg-path="$options.AddUserSvg"
        class="gl-mt-3"
        @close="dismiss"
      >
        <p>{{ $options.i18n.body }}</p>
      </gl-banner>
    </template>
  </user-callout-dismisser>
</template>
