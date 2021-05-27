<script>
import importGroupIllustration from '@gitlab/svgs/dist/illustrations/group-import.svg';
import newGroupIllustration from '@gitlab/svgs/dist/illustrations/group-new.svg';

import { s__ } from '~/locale';
import NewNamespacePage from '~/vue_shared/new_namespace/new_namespace_page.vue';
import createGroupDescriptionDetails from './create_group_description_details.vue';

const PANELS = [
  {
    name: 'create-group-pane',
    selector: '#create-group-pane',
    title: s__('GroupsNew|Create group'),
    description: s__(
      'GroupsNew|Assemble related projects together and grant members access to several projects at once.',
    ),
    illustration: newGroupIllustration,
    details: createGroupDescriptionDetails,
  },
  {
    name: 'import-group-pane',
    selector: '#import-group-pane',
    title: s__('GroupsNew|Import group'),
    description: s__(
      'GroupsNew|Export groups with all their related data and move to a new GitLab instance.',
    ),
    illustration: importGroupIllustration,
    details: 'Migrate your existing groups from another instance of GitLab.',
  },
];

export default {
  components: {
    NewNamespacePage,
  },
  props: {
    hasErrors: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  PANELS,
};
</script>

<template>
  <new-namespace-page
    :jump-to-last-persisted-panel="hasErrors"
    :initial-breadcrumb="s__('New group')"
    :panels="$options.PANELS"
    :title="s__('GroupsNew|Create new group')"
    persistence-key="new_group_last_active_tab"
  />
</template>
