<script>
import importGroupIllustration from '@gitlab/svgs/dist/illustrations/group-import.svg?raw';
import newGroupIllustration from '@gitlab/svgs/dist/illustrations/group-new.svg?raw';

import { s__ } from '~/locale';
import NewNamespacePage from '~/vue_shared/new_namespace/new_namespace_page.vue';
import createGroupDescriptionDetails from './create_group_description_details.vue';

export default {
  components: {
    NewNamespacePage,
  },
  props: {
    rootPath: {
      type: String,
      required: true,
    },
    groupsUrl: {
      type: String,
      required: true,
    },
    parentGroupUrl: {
      type: String,
      required: false,
      default: null,
    },
    parentGroupName: {
      type: String,
      required: false,
      default: '',
    },
    importExistingGroupPath: {
      type: String,
      required: false,
      default: '',
    },
    hasErrors: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    initialBreadcrumbs() {
      return this.parentGroupUrl
        ? [
            { text: this.parentGroupName, href: this.parentGroupUrl },
            { text: s__('GroupsNew|New subgroup'), href: '#' },
          ]
        : [
            { text: s__('Navigation|Your work'), href: this.rootPath },
            { text: s__('GroupsNew|Groups'), href: this.groupsUrl },
            { text: s__('GroupsNew|New group'), href: '#' },
          ];
    },
    panels() {
      return [
        {
          name: 'create-group-pane',
          selector: '#create-group-pane',
          title: this.parentGroupName
            ? s__('GroupsNew|Create subgroup')
            : s__('GroupsNew|Create group'),
          description: s__(
            'GroupsNew|Assemble related projects together and grant members access to several projects at once.',
          ),
          illustration: newGroupIllustration,
          details: createGroupDescriptionDetails,
          detailProps: {
            parentGroupName: this.parentGroupName,
            importExistingGroupPath: this.importExistingGroupPath,
          },
        },
        {
          name: 'import-group-pane',
          selector: '#import-group-pane',
          title: s__('GroupsNew|Import group'),
          description: s__(
            'GroupsNew|Import a group and related data from another GitLab instance.',
          ),
          illustration: importGroupIllustration,
          details: 'Migrate your existing groups from another instance of GitLab.',
        },
      ];
    },
  },
};
</script>

<template>
  <new-namespace-page
    :jump-to-last-persisted-panel="hasErrors"
    :initial-breadcrumbs="initialBreadcrumbs"
    :panels="panels"
    :title="s__('GroupsNew|Create new group')"
    persistence-key="new_group_last_active_tab"
  />
</template>
