<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import NewGroupForm from '~/groups/components/new_group_form.vue';

export default {
  name: 'OrganizationGroupsNewApp',
  i18n: {
    pageTitle: __('New group'),
    description1: s__(
      'GroupsNew|%{linkStart}Groups%{linkEnd} allow you to manage and collaborate across multiple projects. Members of a group have access to all of its projects.',
    ),
    description2: s__(
      'GroupsNew|Groups can also be nested by creating %{linkStart}subgroups%{linkEnd}.',
    ),
  },
  groupsHelpPagePath: helpPagePath('user/group/index'),
  subgroupsHelpPagePath: helpPagePath('user/group/subgroups/index'),
  components: {
    GlLink,
    GlSprintf,
    NewGroupForm,
  },
  inject: [
    'organizationId',
    'basePath',
    'groupsOrganizationPath',
    'mattermostEnabled',
    'availableVisibilityLevels',
    'restrictedVisibilityLevels',
    'pathMaxlength',
    'pathPattern',
  ],
};
</script>

<template>
  <div class="gl-py-6">
    <h1 class="gl-mt-0 gl-font-size-h-display">{{ $options.i18n.pageTitle }}</h1>
    <p>
      <gl-sprintf :message="$options.i18n.description1">
        <template #link="{ content }">
          <gl-link :href="$options.groupsHelpPagePath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <p>
      <gl-sprintf :message="$options.i18n.description2">
        <template #link="{ content }">
          <gl-link :href="$options.subgroupsHelpPagePath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <new-group-form
      :base-path="basePath"
      :path-maxlength="pathMaxlength"
      :path-pattern="pathPattern"
      :cancel-path="groupsOrganizationPath"
    />
  </div>
</template>
