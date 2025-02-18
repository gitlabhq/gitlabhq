<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

const DESCRIPTION_DETAILS = {
  group: [
    s__(
      'GroupsNew|%{linkStart}Groups%{linkEnd} allow you to manage and collaborate across multiple projects. Members of a group have access to all of its projects.',
    ),
    s__('GroupsNew|Groups can also be nested by creating %{linkStart}subgroups%{linkEnd}.'),
  ],
  subgroup: [
    s__(
      'GroupsNew|%{groupsLinkStart}Groups%{groupsLinkEnd} and %{subgroupsLinkStart}subgroups%{subgroupsLinkEnd} allow you to manage and collaborate across multiple projects. Members of a group have access to all of its projects.',
    ),
    s__('GroupsNew|You can also %{linkStart}import an existing group%{linkEnd}.'),
  ],
};

export default {
  components: {
    GlLink,
    GlSprintf,
  },
  paths: {
    groupsHelpPath: helpPagePath('user/group/_index'),
    subgroupsHelpPath: helpPagePath('user/group/subgroups/_index'),
  },
  props: {
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
  },
  descriptionDetails: DESCRIPTION_DETAILS,
};
</script>

<template>
  <div>
    <p>
      <gl-sprintf v-if="parentGroupName" :message="$options.descriptionDetails.subgroup[0]">
        <template #groupsLink="{ content }">
          <gl-link :href="$options.paths.groupsHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
        <template #subgroupsLink="{ content }">
          <gl-link :href="$options.paths.subgroupsHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
      <gl-sprintf v-else :message="$options.descriptionDetails.group[0]">
        <template #link="{ content }">
          <gl-link :href="$options.paths.groupsHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <p>
      <gl-sprintf v-if="parentGroupName" :message="$options.descriptionDetails.subgroup[1]">
        <template #link="{ content }">
          <gl-link :href="importExistingGroupPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
      <gl-sprintf v-else :message="$options.descriptionDetails.group[1]">
        <template #link="{ content }">
          <gl-link :href="$options.paths.subgroupsHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
  </div>
</template>
