<script>
import {
  GlModal,
  GlCollapsibleListbox,
  GlTooltipDirective as GlTooltip,
  GlAlert,
} from '@gitlab/ui';
import { __ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrl } from '~/lib/utils/url_utility';
import { findHierarchyWidget } from '~/work_items/utils';
import moveIssueMutation from '~/sidebar/queries/move_issue.mutation.graphql';
import searchUserProjectsToMove from '~/work_items/graphql/search_user_projects_to_move.query.graphql';
import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import { DEFAULT_PAGE_SIZE_CHILD_ITEMS } from '~/work_items/constants';

export default {
  components: { GlModal, GlCollapsibleListbox, GlAlert },
  directives: {
    GlTooltip,
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    fullPath: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
  },
  actionCancel: {
    text: __('Cancel'),
  },
  data() {
    return {
      isModalVisible: false,
      shouldFetch: false,
      projects: [],
      selectedProjectId: null,
      noResultsText: '',
      searchTerm: '',
      moveInProgress: false,
      hasChildren: false,
      errorFetchingChildren: false,
      showErrorMessage: false,
    };
  },
  apollo: {
    projects: {
      query() {
        return searchUserProjectsToMove;
      },
      variables() {
        return {
          search: this.searchTerm,
          sort: this.searchTerm ? 'similarity' : 'stars_desc',
        };
      },
      skip() {
        return !this.shouldFetch;
      },
      update(data) {
        return data?.projects?.nodes ?? [];
      },
      result() {
        if (!this.projects?.length) {
          this.noResultsText = __('No project found');
        }
      },
      error() {
        this.noResultsText = __('Failed to load projects');
      },
    },
    hasChildren: {
      query: getWorkItemTreeQuery,
      variables() {
        return {
          id: this.workItemId,
          pageSize: DEFAULT_PAGE_SIZE_CHILD_ITEMS,
          endCursor: '',
        };
      },
      skip() {
        return !this.workItemId;
      },
      update(data) {
        return findHierarchyWidget(data?.workItem)?.hasChildren;
      },
      error() {
        // If was not able to fetch children, show warning message anyway just in case
        this.errorFetchingChildren = true;
      },
    },
  },
  computed: {
    isLoadingProjects() {
      return this.$apollo.queries.projects.loading;
    },
    listboxItems() {
      // Remove current project from the list as issue already belongs to it
      return this.projects
        .filter((project) => project?.id !== this.projectId)
        .map((item) => ({
          value: item.id,
          text: item.nameWithNamespace,
          fullPath: item.fullPath,
        }));
    },
    selectedProjectNamespace() {
      return this.projects?.find((project) => project?.id === this.selectedProjectId)
        ?.nameWithNamespace;
    },
    actionPrimary() {
      return {
        text: __('Move'),
        attributes: {
          variant: 'confirm',
          loading: this.moveInProgress,
          disabled: !this.selectedProjectId || this.moveInProgress,
        },
      };
    },
    showChildrenWarning() {
      return Boolean(this.selectedProjectId) && (this.hasChildren || this.errorFetchingChildren);
    },
  },
  watch: {
    visible: {
      immediate: true,
      handler(visible) {
        this.isModalVisible = visible;
      },
    },
  },
  methods: {
    hideModal() {
      this.selectedProjectId = null;
      this.$emit('hideModal');
      this.isModalVisible = false;
      this.showErrorMessage = false;
    },
    onDropdownShown() {
      this.searchTerm = '';
      this.showErrorMessage = false;
      this.shouldFetch = true;
    },
    search(searchTerm) {
      this.searchTerm = searchTerm;
    },
    async moveIssue(event) {
      event.preventDefault();

      this.moveInProgress = true;

      const targetProjectPath = this.listboxItems?.find(
        (project) => project?.value === this.selectedProjectId,
      )?.fullPath;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: moveIssueMutation,
          variables: {
            moveIssueInput: {
              projectPath: this.fullPath,
              iid: this.workItemIid,
              targetProjectPath,
            },
          },
        });

        const { errors } = data.issueMove;

        if (!data.issueMove || errors?.length) {
          this.showErrorMessage = true;
          if (errors) {
            Sentry.captureException(errors[0].message);
          }
        } else {
          this.hideModal();
          visitUrl(data.issueMove?.issue?.webUrl);
        }
      } catch (error) {
        this.showErrorMessage = true;
        Sentry.captureException(error);
      } finally {
        this.moveInProgress = false;
      }
    },
  },
};
</script>
<template>
  <gl-modal
    modal-id="move-work-item-modal"
    :visible="isModalVisible"
    size="sm"
    :title="s__('WorkItem|Move')"
    :aria-label="s__('WorkItem|Move')"
    :action-primary="actionPrimary"
    :action-cancel="$options.actionCancel"
    @primary="moveIssue"
    @canceled="hideModal"
    @hidden="hideModal"
  >
    <gl-alert
      v-if="showErrorMessage"
      class="gl-mb-4"
      variant="danger"
      @dismiss="showErrorMessage = false"
    >
      {{ __('Could not be moved. Select another project or try again.') }}
    </gl-alert>

    <p class="gl-mb-2 gl-font-bold">{{ __('Project') }}</p>

    <gl-collapsible-listbox
      v-model="selectedProjectId"
      :items="listboxItems"
      block
      fluid-width
      searchable
      :searching="isLoadingProjects"
      :no-results-text="noResultsText"
      :disabled="moveInProgress"
      @shown="onDropdownShown"
      @search="search"
    >
      <template #list-item="{ item }">
        <span class="gl-break-words">{{ item.text }}</span>
      </template>
    </gl-collapsible-listbox>
    <p
      v-if="selectedProjectId"
      class="gl-mt-2 gl-text-secondary"
      data-testid="selected-project-namespace"
    >
      {{ selectedProjectNamespace }}
    </p>

    <p v-if="showChildrenWarning" data-testid="child-items-warning">
      {{ __('All child items will also be moved to the selected location.') }}
    </p>
  </gl-modal>
</template>
