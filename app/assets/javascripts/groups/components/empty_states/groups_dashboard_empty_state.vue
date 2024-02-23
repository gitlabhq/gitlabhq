<script>
import { GlEmptyState } from '@gitlab/ui';

import { s__ } from '~/locale';

export default {
  components: { GlEmptyState },
  inject: ['groupsEmptyStateIllustration', 'newGroupPath', 'exploreGroupsPath'],
  i18n: {
    title: s__('GroupsEmptyState|A group is a collection of several projects'),
    description: s__(
      'GroupsEmptyState|If you organize your projects under a group, it works like a folder. You can manage the permissions and access of your group members for each project in the group.',
    ),
    secondary_button_text: s__('GroupsEmptyState|Explore groups'),
    primary_button_text: s__('GroupsEmptyState|New group'),
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :description="$options.i18n.description"
    :svg-path="groupsEmptyStateIllustration"
    :primary-button-text="$options.i18n.primary_button_text"
    :primary-button-link="newGroupPath"
    :secondary-button-text="$options.i18n.secondary_button_text"
    :secondary-button-link="exploreGroupsPath"
    data-testid="groups-empty-state"
  />
</template>
