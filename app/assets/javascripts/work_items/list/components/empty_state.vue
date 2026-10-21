<script>
import jiraCloudAppLogo from '@gitlab/svgs/dist/illustrations/third-party-logos/integrations-logos/jira_cloud_app.svg?raw';
import { GlButton, GlEmptyState } from '@gitlab/ui';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  jiraCloudAppLogo,
  name: 'EmptyState',
  components: {
    GlButton,
    GlEmptyState,
    HelpPageLink,
  },
  directives: {
    SafeHtml,
  },
  inject: ['canCreateProjects', 'newProjectPath', 'signInPath', 'isGroup'],
  props: {
    hasProjects: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasEpicsFeature: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    showNewProjectButton() {
      return this.canCreateProjects && this.isGroup && !this.hasProjects;
    },
    description() {
      return this.showNewProjectButton && this.hasEpicsFeature
        ? s__(
            'WorkItem|Use epics to collaborate on ideas, solve problems, and plan work across this group. To track other work items, create a project.',
          )
        : s__(
            'WorkItem|Use work items (also known as tickets or stories on other platforms) to collaborate on ideas, solve problems, and plan your project.',
          );
    },
    newProjectButtonVariant() {
      // Without epics there is no "New item" button, so "New project" is the only action
      return this.hasEpicsFeature ? 'default' : 'confirm';
    },
  },
};
</script>

<template>
  <div
    data-testid="signed-in-empty-state-block"
    :data-track-action="isLoggedIn && !isGroup && 'render'"
    :data-track-label="isLoggedIn && !isGroup && 'project_issues_empty_list'"
  >
    <gl-empty-state
      :title="s__('WorkItem|Track bugs, plan features, and organize your efforts with work items')"
      :description="description"
      illustration-name="empty-issues-add-md"
      :primary-button-text="isLoggedIn ? undefined : __('Register / Sign In')"
      :primary-button-link="isLoggedIn ? undefined : signInPath"
      data-testid="issuable-empty-state"
    >
      <template v-if="isLoggedIn" #actions>
        <div class="gl-flex gl-justify-center gl-gap-3">
          <slot name="new-issue-button"></slot>
          <gl-button
            v-if="showNewProjectButton"
            :href="newProjectPath"
            :variant="newProjectButtonVariant"
          >
            {{ __('New project') }}
          </gl-button>
        </div>
      </template>
    </gl-empty-state>
    <template v-if="isLoggedIn">
      <hr class="gl-mb-7" />
      <div class="gl-flex gl-justify-center">
        <span
          v-safe-html="$options.jiraCloudAppLogo"
          class="jira-logo-white gl-inline-flex gl-size-6 gl-items-center gl-rounded-base gl-bg-blue-500 gl-p-1"
        ></span>
        <p class="gl-mb-0 gl-ml-3 gl-mt-1">
          {{ s__('JiraService|Using Jira for issue tracking?') }}
          <help-page-link
            href="integration/jira/_index"
            :data-track-action="!isGroup && 'click_jira_int_project_issues_empty_list_page'"
            :data-track-label="!isGroup && 'jira_int_project_issues_empty_list'"
          >
            {{ s__('JiraService|See integration options') }}
          </help-page-link>
        </p>
      </div>
    </template>
  </div>
</template>

<style scoped>
.jira-logo-white :deep(svg path) {
  fill: white;
}
</style>
