<script>
import { GlEmptyState, GlSprintf } from '@gitlab/ui';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';

import { s__ } from '~/locale';

export default {
  components: { GlEmptyState, HelpPageLink, GlSprintf },
  i18n: {
    title: s__('GroupsEmptyState|This group has not been invited to any other projects.'),
    description: s__(
      'GroupsEmptyState|Projects this group has been %{linkStart}invited to%{linkEnd} will appear here.',
    ),
  },
  inject: ['emptyProjectsIllustration'],
};
</script>

<template>
  <gl-empty-state :title="$options.i18n.title" :svg-path="emptyProjectsIllustration">
    <template #description>
      <gl-sprintf :message="$options.i18n.description">
        <template #link="{ content }">
          <help-page-link
            href="user/project/members/sharing_projects_groups"
            anchor="invite-a-group-to-a-project"
            >{{ content }}</help-page-link
          >
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
