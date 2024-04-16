<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import NewGroupForm from '~/groups/components/new_group_form.vue';
import { FORM_FIELD_NAME, FORM_FIELD_PATH, FORM_FIELD_VISIBILITY_LEVEL } from '~/groups/constants';
import { VISIBILITY_LEVELS_INTEGER_TO_STRING } from '~/visibility_level/constants';
import { createGroup } from '~/rest_api';
import { createAlert } from '~/alert';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';

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
    errorMessage: s__(
      'Organization|An error occurred creating a group in this organization. Please try again.',
    ),
    successMessage: __('Group %{group_name} was successfully created.'),
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
    'defaultVisibilityLevel',
    'pathMaxlength',
    'pathPattern',
  ],
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    initialFormValues() {
      return {
        [FORM_FIELD_NAME]: '',
        [FORM_FIELD_PATH]: '',
        [FORM_FIELD_VISIBILITY_LEVEL]: this.defaultVisibilityLevel,
      };
    },
  },
  methods: {
    async onSubmit({
      [FORM_FIELD_NAME]: name,
      [FORM_FIELD_PATH]: path,
      [FORM_FIELD_VISIBILITY_LEVEL]: visibilityLevelInteger,
    }) {
      try {
        this.loading = true;
        const { data: group } = await createGroup({
          organization_id: this.organizationId,
          name,
          path,
          visibility: VISIBILITY_LEVELS_INTEGER_TO_STRING[visibilityLevelInteger],
        });

        visitUrlWithAlerts(group.web_url, [
          {
            id: 'organization-group-successfully-created',
            message: sprintf(this.$options.i18n.successMessage, { group_name: group.full_name }),
            variant: 'info',
          },
        ]);
      } catch (error) {
        this.loading = false;
        // We cannot show specific error message until https://gitlab.com/gitlab-org/gitlab/-/issues/443588 is completed
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      }
    },
  },
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
      :loading="loading"
      :base-path="basePath"
      :path-maxlength="pathMaxlength"
      :path-pattern="pathPattern"
      :cancel-path="groupsOrganizationPath"
      :available-visibility-levels="availableVisibilityLevels"
      :restricted-visibility-levels="restrictedVisibilityLevels"
      :initial-form-values="initialFormValues"
      @submit="onSubmit"
    />
  </div>
</template>
