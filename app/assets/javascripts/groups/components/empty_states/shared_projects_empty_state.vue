<script>
import { GlSprintf } from '@gitlab/ui';
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { s__ } from '~/locale';
import { SEARCH_MINIMUM_LENGTH } from '../../constants';

export default {
  components: { ResourceListsEmptyState, HelpPageLink, GlSprintf },
  SEARCH_MINIMUM_LENGTH,
  i18n: {
    title: s__('GroupsEmptyState|This group has not been invited to any other projects.'),
    description: s__(
      'GroupsEmptyState|Projects this group has been %{linkStart}invited to%{linkEnd} will appear here.',
    ),
  },
  inject: ['emptyProjectsIllustration'],
  props: {
    search: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <resource-lists-empty-state
    :title="$options.i18n.title"
    :svg-path="emptyProjectsIllustration"
    :search="search"
    :search-minimum-length="$options.SEARCH_MINIMUM_LENGTH"
  >
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
  </resource-lists-empty-state>
</template>
