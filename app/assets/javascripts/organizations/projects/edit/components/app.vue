<script>
import { GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import NewEditForm from '~/projects/components/new_edit_form.vue';

export default {
  name: 'OrganizationProjectsEditApp',
  components: { GlSprintf, NewEditForm },
  i18n: {
    pageTitle: __('Edit project: %{project_name}'),
  },
  inject: ['projectsOrganizationPath', 'previewMarkdownPath', 'project'],
  data() {
    return {
      loading: false,
    };
  },
  methods: {
    async onSubmit() {
      // Make API call. Coming in future MR
    },
  },
};
</script>

<template>
  <div class="gl-py-6">
    <h1 class="gl-mt-0 gl-font-size-h-display">
      <gl-sprintf :message="$options.i18n.pageTitle">
        <template #project_name>{{ project.fullName }}</template>
      </gl-sprintf>
    </h1>
    <new-edit-form
      :loading="loading"
      :initial-form-values="project"
      :preview-markdown-path="previewMarkdownPath"
      :cancel-button-href="projectsOrganizationPath"
      @submit="onSubmit"
    />
  </div>
</template>
