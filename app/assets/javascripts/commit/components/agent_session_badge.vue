<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'AgentSessionBadge',
  i18n: {
    label: s__('DuoAgentPlatform|GitLab Duo Agent session'),
    tooltip: s__('DuoAgentPlatform|Commit authored in a GitLab Duo Agent session'),
  },
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <gl-badge
    v-gl-tooltip
    icon="session-ai"
    variant="info"
    class="gl-h-6"
    :title="$options.i18n.tooltip"
    :aria-label="$options.i18n.label"
    data-testid="commit-agent-session-badge"
  />
</template>
