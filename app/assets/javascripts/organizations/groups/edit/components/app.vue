<script>
import { GlSprintf } from '@gitlab/ui';
import NewEditForm from '~/groups/components/new_edit_form.vue';
import { __ } from '~/locale';

export default {
  name: 'OrganizationGroupsEditApp',
  components: { GlSprintf, NewEditForm },
  i18n: {
    pageTitle: __('Edit group: %{group_name}'),
    submitButtonText: __('Save changes'),
  },
  inject: [
    'group',
    'basePath',
    'groupsAndProjectsOrganizationPath',
    'groupsOrganizationPath',
    'availableVisibilityLevels',
    'restrictedVisibilityLevels',
    'defaultVisibilityLevel',
    'pathMaxlength',
    'pathPattern',
  ],
};
</script>

<template>
  <div class="gl-py-6">
    <h1 class="gl-mt-0 gl-font-size-h-display">
      <gl-sprintf :message="$options.i18n.pageTitle">
        <template #group_name>{{ group.fullName }}</template>
      </gl-sprintf>
    </h1>
    <new-edit-form
      :loading="false"
      :base-path="basePath"
      :path-maxlength="pathMaxlength"
      :path-pattern="pathPattern"
      :submit-button-text="$options.i18n.submitButtonText"
      :cancel-path="groupsAndProjectsOrganizationPath"
      :available-visibility-levels="availableVisibilityLevels"
      :restricted-visibility-levels="restrictedVisibilityLevels"
      :initial-form-values="group"
    />
  </div>
</template>
