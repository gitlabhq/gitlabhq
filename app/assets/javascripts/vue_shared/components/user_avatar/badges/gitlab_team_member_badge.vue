<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

const GITLAB_TEAM_MEMBER_LABEL = __('GitLab Team Member');

export default {
  name: 'GitlabTeamMemberBadge',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: { GlIcon },
  gitlabTeamMemberLabel: GITLAB_TEAM_MEMBER_LABEL,
};
</script>

<template>
  <span
    v-gl-tooltip.hover
    :title="$options.gitlabTeamMemberLabel"
    role="img"
    :aria-label="$options.gitlabTeamMemberLabel"
    class="d-inline-block align-middle"
  >
    <gl-icon name="tanuki-verified" class="gl-text-purple d-block" />
  </span>
</template>
