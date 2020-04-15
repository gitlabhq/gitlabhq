<script>
import { GlAvatar, GlButton, GlFormGroup, GlFormSelect, GlLabel } from '@gitlab/ui';

export default {
  name: 'JiraImportForm',
  components: {
    GlAvatar,
    GlButton,
    GlFormGroup,
    GlFormSelect,
    GlLabel,
  },
  currentUserAvatarUrl: gon.current_user_avatar_url,
  currentUsername: gon.current_username,
};
</script>

<template>
  <div>
    <h3 class="page-title">{{ __('New Jira import') }}</h3>
    <hr />
    <form>
      <gl-form-group
        class="row align-items-center"
        :label="__('Import from')"
        label-cols-sm="2"
        label-for="jira-project-select"
      >
        <gl-form-select id="jira-project-select" class="mb-2" />
      </gl-form-group>

      <gl-form-group
        class="row align-items-center"
        :label="__('Issue label')"
        label-cols-sm="2"
        label-for="jira-project-label"
      >
        <gl-label
          id="jira-project-label"
          class="mb-2"
          background-color="#428BCA"
          title="jira-import::KEY-1"
          scoped
        />
      </gl-form-group>

      <hr />

      <p class="offset-md-1">
        {{
          __(
            "For each Jira issue successfully imported, we'll create a new GitLab issue with the following data:",
          )
        }}
      </p>

      <gl-form-group
        class="row align-items-center mb-1"
        :label="__('Title')"
        label-cols-sm="2"
        label-for="jira-project-title"
      >
        <p id="jira-project-title" class="mb-2">{{ __('jira.issue.summary') }}</p>
      </gl-form-group>
      <gl-form-group
        class="row align-items-center mb-1"
        :label="__('Reporter')"
        label-cols-sm="2"
        label-for="jira-project-reporter"
      >
        <gl-avatar
          id="jira-project-reporter"
          class="mb-2"
          :src="$options.currentUserAvatarUrl"
          :size="24"
          :aria-label="$options.currentUsername"
        />
      </gl-form-group>
      <gl-form-group
        class="row align-items-center mb-1"
        :label="__('Description')"
        label-cols-sm="2"
        label-for="jira-project-description"
      >
        <p id="jira-project-description" class="mb-2">{{ __('jira.issue.description.content') }}</p>
      </gl-form-group>

      <div class="footer-block row-content-block d-flex justify-content-between">
        <gl-button category="primary" variant="success">{{ __('Next') }}</gl-button>
        <gl-button>{{ __('Cancel') }}</gl-button>
      </div>
    </form>
  </div>
</template>
