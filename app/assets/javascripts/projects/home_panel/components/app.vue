<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { isLoggedIn } from '~/lib/utils/common_utils';
import ForksButton from '~/forks/components/forks_button.vue';
import NotificationsDropdown from '~/notifications/components/notifications_dropdown.vue';
import StarCount from '~/stars/components/star_count.vue';
import getProjectByPath from '~/graphql_shared/queries/get_project_by_path.graphql';
import { ACTION_COPY_ID } from '~/vue_shared/components/list_actions/constants';
import { createAlert } from '~/alert';
import { formatProject } from '~/projects/home_panel/formatter';
import ProjectHeaderActions from './header_actions.vue';

export default {
  name: 'HomePanelApp',
  components: {
    ForksButton,
    GlButton,
    ProjectHeaderActions,
    NotificationsDropdown,
    StarCount,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    adminPath: {
      default: '',
    },
    canReadProject: {
      default: false,
    },
    isProjectEmpty: {
      default: false,
    },
    projectId: {
      default: '',
    },
    projectFullPath: {
      default: '',
    },
  },
  props: {
    canRequestAccess: {
      type: Boolean,
      required: true,
    },
    canWithdrawAccessRequest: {
      type: Boolean,
      required: true,
    },
    requestAccessPath: {
      type: String,
      required: true,
    },
    withdrawAccessRequestPath: {
      type: String,
      required: true,
    },
    dashboardPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    project: {
      query: getProjectByPath,
      update(data) {
        return formatProject(data.project, {
          canWithdrawAccessRequest: this.canWithdrawAccessRequest,
          canRequestAccess: this.canRequestAccess,
          requestAccessPath: this.requestAccessPath,
          withdrawAccessRequestPath: this.withdrawAccessRequestPath,
        });
      },
      variables() {
        return { fullPath: this.projectFullPath };
      },
      error() {
        createAlert({
          message: s__(
            'GroupProjectActions|Something went wrong while loading the actions dropdown list. Please refresh the page and try again.',
          ),
        });
      },
      skip() {
        return !isLoggedIn();
      },
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
      project: { id: this.projectId, availableActions: [ACTION_COPY_ID] },
    };
  },
  computed: {
    canForkProject() {
      return !this.isProjectEmpty && isLoggedIn() && this.canReadProject;
    },
    copyProjectId() {
      return sprintf(s__('ProjectPage|Project ID: %{id}'), { id: this.projectId });
    },
    showActions() {
      return this.project && !this.$apollo.queries.project.loading;
    },
  },
  i18n: {
    adminButtonTooltip: __('View project in admin area'),
  },
};
</script>

<template>
  <div
    class="gl-justify-content-md-end project-repo-buttons gl-flex gl-flex-wrap gl-items-center gl-gap-3"
  >
    <gl-button
      v-if="adminPath"
      v-gl-tooltip
      :aria-label="$options.i18n.adminButtonTooltip"
      :href="adminPath"
      :title="$options.i18n.adminButtonTooltip"
      data-testid="admin-button"
      icon="admin"
    />

    <template v-if="isLoggedIn && canReadProject">
      <notifications-dropdown />
    </template>

    <star-count />

    <forks-button v-if="canForkProject" />

    <template v-if="canReadProject">
      <span class="gl-sr-only" itemprop="identifier" data-testid="project-id-content">
        {{ copyProjectId }}
      </span>
    </template>

    <project-header-actions v-if="showActions" :project="project" :dashboard-path="dashboardPath" />
  </div>
</template>
