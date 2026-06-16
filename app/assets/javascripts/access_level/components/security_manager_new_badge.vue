<script>
import { GlBadge, GlPopover, GlSprintf } from '@gitlab/ui';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { s__, __ } from '~/locale';

export default {
  name: 'SecurityManagerNewBadge',
  badgeId: 'security-manager-role-badge',
  i18n: {
    badge: __('New'),
    popoverTitle: s__('MemberRole|Security Manager role now available'),
    popoverBody: s__(
      'MemberRole|The Security Manager role provides comprehensive access to security features, including vulnerability management, security dashboards, policy configuration, and compliance tools. Designed for users who manage security and compliance across your organization. %{linkStart}Learn more.%{linkEnd}',
    ),
  },
  components: { GlBadge, GlPopover, GlSprintf, HelpPageLink },
};
</script>

<template>
  <gl-badge :id="$options.badgeId" variant="info">
    {{ $options.i18n.badge }}

    <gl-popover
      :target="$options.badgeId"
      :title="$options.i18n.popoverTitle"
      css-classes="gl-max-w-xs"
      placement="top"
      boundary="viewport"
    >
      <gl-sprintf :message="$options.i18n.popoverBody">
        <template #link="{ content }">
          <help-page-link href="user/permissions" target="_blank">{{ content }}</help-page-link>
        </template>
      </gl-sprintf>
    </gl-popover>
  </gl-badge>
</template>
