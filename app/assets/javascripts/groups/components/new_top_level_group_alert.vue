<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'NewTopLevelGroupAlert',
  components: {
    GlAlert,
    UserCalloutDismisser,
  },
  i18n: {
    titleText: s__("Groups|You're creating a new top-level group"),
    bodyText: s__(
      'Groups|Members, projects, trials, and paid subscriptions are tied to a specific top-level group. If you are already a member of a top-level group, you can create a subgroup so your new work is part of your existing top-level group. Do you want to create a subgroup instead?',
    ),
    primaryBtnText: s__('Groups|Learn more about subgroups'),
  },
  subgroupsDocsPath: helpPagePath('user/group/subgroups/_index'),
};
</script>

<template>
  <user-callout-dismisser feature-name="new_top_level_group_alert">
    <template #default="{ dismiss, shouldShowCallout }">
      <gl-alert
        v-if="shouldShowCallout"
        ref="newTopLevelAlert"
        data-testid="new-top-level-alert"
        :title="$options.i18n.titleText"
        :primary-button-text="$options.i18n.primaryBtnText"
        :primary-button-link="$options.subgroupsDocsPath"
        @dismiss="dismiss"
      >
        {{ $options.i18n.bodyText }}
      </gl-alert>
    </template>
  </user-callout-dismisser>
</template>
