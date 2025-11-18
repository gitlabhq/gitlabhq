<script>
import emptyStateSvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-issues-add-md.svg';
import jiraCloudAppLogo from '@gitlab/svgs/dist/illustrations/third-party-logos/integrations-logos/jira_cloud_app.svg?raw';
import { GlButton, GlEmptyState, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { hasNewIssueDropdown } from '../has_new_issue_dropdown_mixin';

export default {
  emptyStateSvg,
  issuesHelpPagePath: helpPagePath('user/project/issues/_index'),
  jiraIntegrationPath: helpPagePath('integration/jira/_index'),
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
    NewResourceDropdown,
  },
  directives: {
    SafeHtml,
  },
  mixins: [hasNewIssueDropdown()],
  inject: [
    'canCreateProjects',
    'isSignedIn',
    'newIssuePath',
    'newProjectPath',
    'showNewIssueLink',
    'signInPath',
    'groupId',
    'isProject',
  ],
  props: {
    showNewIssueDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasProjects: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    showNewProjectButton() {
      return this.canCreateProjects && !this.isProject && !this.hasProjects;
    },
  },
  jiraCloudAppLogo,
};
</script>

<template>
  <div
    v-if="isSignedIn"
    data-testid="signed-in-empty-state-block"
    :data-track-action="isProject && 'render'"
    :data-track-label="isProject && 'project_issues_empty_list'"
  >
    <div>
      <gl-empty-state
        :title="s__('Issues|Track bugs, plan features, and organize your work with issues')"
        :description="
          s__(
            'Issues|Use issues (also known as tickets or stories on other platforms) to collaborate on ideas, solve problems, and plan your project.',
          )
        "
        :svg-path="$options.emptyStateSvg"
        data-testid="issuable-empty-state"
      >
        <template #actions>
          <div class="gl-flex gl-justify-center gl-gap-3">
            <slot name="actions"></slot>
            <new-resource-dropdown
              v-if="showNewIssueDropdown"
              class="gl-self-center"
              :query="$options.searchProjectsQuery"
              :query-variables="newIssueDropdownQueryVariables"
              :extract-projects="extractProjects"
              :group-id="groupId"
            />
            <gl-button
              v-else-if="showNewProjectButton"
              :href="newProjectPath"
              :variant="showNewIssueDropdown ? 'default' : 'confirm'"
            >
              {{ __('New project') }}
            </gl-button>
            <slot v-else name="new-issue-button">
              <gl-button
                v-if="showNewIssueLink"
                :href="newIssuePath"
                variant="confirm"
                data-track-action="click_new_issue_project_issues_empty_list_page"
                data-track-label="new_issue_project_issues_empty_list"
              >
                {{ __('Create issue') }}
              </gl-button>
            </slot>
          </div>
        </template>
      </gl-empty-state>
      <hr class="gl-mb-7" />
      <div class="gl-flex gl-justify-center">
        <span
          v-safe-html="$options.jiraCloudAppLogo"
          class="jira-logo-white gl-inline-flex gl-size-6 gl-items-center gl-rounded-base gl-bg-blue-500 gl-p-1"
        ></span>
        <p class="gl-mb-0 gl-ml-3 gl-mt-1">
          {{ s__('JiraService|Using Jira for issue tracking?') }}
          <gl-link
            :href="$options.jiraIntegrationPath"
            :data-track-action="isProject && 'click_jira_int_project_issues_empty_list_page'"
            :data-track-label="isProject && 'jira_int_project_issues_empty_list'"
          >
            {{ s__('JiraService|See integration options') }}
          </gl-link>
        </p>
      </div>
    </div>
  </div>

  <gl-empty-state
    v-else
    :title="s__('Issues|Track bugs, plan features, and organize your work with issues')"
    :description="
      s__(
        'Issues|Use issues (also known as tickets or stories on other platforms) to collaborate on ideas, solve problems, and plan your project.',
      )
    "
    :svg-path="$options.emptyStateSvg"
    :svg-height="null"
    :primary-button-text="__('Register / Sign In')"
    :primary-button-link="signInPath"
    data-testid="issuable-empty-state"
  />
</template>

<style scoped>
.jira-logo-white :deep(svg path) {
  fill: white;
}
</style>
