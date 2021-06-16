<script>
import { GlButton, GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlPopover,
  },
  props: {
    helpPath: {
      type: String,
      required: true,
    },
    discoverProjectSecurityPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  i18n: {
    securityReportsHelp: s__('SecurityReports|Security reports help page link'),
    upgradeToManageVulnerabilities: s__('SecurityReports|Upgrade to manage vulnerabilities'),
    upgradeToInteract: s__(
      'SecurityReports|Upgrade to interact, track and shift left with vulnerability management features in the UI.',
    ),
  },
};
</script>

<template>
  <span v-if="discoverProjectSecurityPath">
    <gl-button
      ref="discoverProjectSecurity"
      icon="question-o"
      category="tertiary"
      :aria-label="$options.i18n.upgradeToManageVulnerabilities"
    />

    <gl-popover
      :target="() => $refs.discoverProjectSecurity.$el"
      :title="$options.i18n.upgradeToManageVulnerabilities"
      placement="top"
      triggers="click blur"
    >
      {{ $options.i18n.upgradeToInteract }}
      <gl-link :href="discoverProjectSecurityPath" target="_blank" class="gl-font-sm">{{
        __('Learn more')
      }}</gl-link>
    </gl-popover>
  </span>

  <gl-link v-else target="_blank" :href="helpPath" :aria-label="$options.i18n.securityReportsHelp">
    <gl-icon name="question-o" />
  </gl-link>
</template>
