<script>
import {
  GlAvatarLabeled,
  GlIcon,
  GlLink,
  GlBadge,
  GlTooltipDirective,
  GlPopover,
  GlSprintf,
  GlTruncateText,
} from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';

import {
  renderDeleteSuccessToast,
  deleteParams,
} from 'ee_else_ce/vue_shared/components/resource_lists/utils';
import ProjectListItemInactiveBadge from 'ee_else_ce/vue_shared/components/projects_list/project_list_item_inactive_badge.vue';
import { VISIBILITY_TYPE_ICON, PROJECT_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import { FEATURABLE_ENABLED } from '~/featurable/constants';
import { __, s__ } from '~/locale';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import { truncate } from '~/lib/utils/text_utility';
import SafeHtml from '~/vue_shared/directives/safe_html';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import DeleteModal from '~/projects/components/shared/delete_modal.vue';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { deleteProject } from '~/rest_api';
import { createAlert } from '~/alert';

const MAX_TOPICS_TO_SHOW = 3;
const MAX_TOPIC_TITLE_LENGTH = 15;

export default {
  i18n: {
    stars: __('Stars'),
    forks: __('Forks'),
    issues: __('Issues'),
    mergeRequests: __('Merge requests'),
    topics: __('Topics'),
    topicsPopoverTargetText: __('+ %{count} more'),
    moreTopics: __('More topics'),
    [TIMESTAMP_TYPE_CREATED_AT]: __('Created'),
    [TIMESTAMP_TYPE_UPDATED_AT]: __('Updated'),
    actions: __('Actions'),
    showMore: __('Show more'),
    showLess: __('Show less'),
    project: __('Project'),
    deleteErrorMessage: s__(
      'Projects|An error occurred deleting the project. Please refresh the page to try again.',
    ),
  },
  truncateTextToggleButtonProps: { class: '!gl-text-sm' },
  components: {
    GlAvatarLabeled,
    GlIcon,
    GlLink,
    GlBadge,
    GlPopover,
    GlSprintf,
    GlTruncateText,
    TimeAgoTooltip,
    DeleteModal,
    ListActions,
    ProjectListItemInactiveBadge,
    ProjectListItemDelayedDeletionModalFooter: () =>
      import(
        'ee_component/vue_shared/components/projects_list/project_list_item_delayed_deletion_modal_footer.vue'
      ),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    /**
     * Expected format:
     *
     * {
     *   id: number | string;
     *   name: string;
     *   webUrl: string;
     *   topics: string[];
     *   forksCount?: number;
     *   avatarUrl: string | null;
     *   starCount: number;
     *   visibility: string;
     *   issuesAccessLevel: string;
     *   forkingAccessLevel: string;
     *   openIssuesCount: number;
     *   maxAccessLevel: {
     *     integerValue: number;
     *   };
     *   descriptionHtml: string;
     *   updatedAt: string;
     *   isForked: boolean;
     *   actions?: ('edit' | 'delete')[];
     *   editPath?: string;
     * }
     */
    project: {
      type: Object,
      required: true,
    },
    showProjectIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
    timestampType: {
      type: String,
      required: false,
      default: TIMESTAMP_TYPE_CREATED_AT,
      validator(value) {
        return [TIMESTAMP_TYPE_CREATED_AT, TIMESTAMP_TYPE_UPDATED_AT].includes(value);
      },
    },
  },
  data() {
    return {
      topicsPopoverTarget: uniqueId('project-topics-popover-'),
      isDeleteModalVisible: false,
      isDeleteLoading: false,
    };
  },
  computed: {
    visibility() {
      return this.project.visibility;
    },
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.visibility];
    },
    visibilityTooltip() {
      return PROJECT_VISIBILITY_TYPE[this.visibility];
    },
    accessLevel() {
      return this.project.accessLevel?.integerValue;
    },
    accessLevelLabel() {
      return ACCESS_LEVEL_LABELS[this.accessLevel];
    },
    shouldShowAccessLevel() {
      return this.accessLevel !== undefined && this.accessLevel !== ACCESS_LEVEL_NO_ACCESS_INTEGER;
    },
    starsHref() {
      return `${this.project.webUrl}/-/starrers`;
    },
    mergeRequestsHref() {
      return `${this.project.webUrl}/-/merge_requests`;
    },
    forksHref() {
      return `${this.project.webUrl}/-/forks`;
    },
    issuesHref() {
      return `${this.project.webUrl}/-/issues`;
    },
    isMergeRequestsEnabled() {
      return (
        this.project.mergeRequestsAccessLevel?.toLowerCase() === FEATURABLE_ENABLED &&
        this.project.openMergeRequestsCount !== undefined
      );
    },
    isForkingEnabled() {
      return (
        this.project.forkingAccessLevel?.toLowerCase() === FEATURABLE_ENABLED &&
        this.project.forksCount !== undefined
      );
    },
    isIssuesEnabled() {
      return (
        this.project.issuesAccessLevel?.toLowerCase() === FEATURABLE_ENABLED &&
        this.project.openIssuesCount !== undefined
      );
    },
    hasTopics() {
      return this.project.topics.length;
    },
    visibleTopics() {
      return this.project.topics.slice(0, MAX_TOPICS_TO_SHOW);
    },
    popoverTopics() {
      return this.project.topics.slice(MAX_TOPICS_TO_SHOW);
    },
    starCount() {
      return numberToMetricPrefix(this.project.starCount);
    },
    openMergeRequestsCount() {
      if (!this.isMergeRequestsEnabled) {
        return null;
      }

      return numberToMetricPrefix(this.project.openMergeRequestsCount);
    },
    forksCount() {
      if (!this.isForkingEnabled) {
        return null;
      }

      return numberToMetricPrefix(this.project.forksCount);
    },
    openIssuesCount() {
      if (!this.isIssuesEnabled) {
        return null;
      }

      return numberToMetricPrefix(this.project.openIssuesCount);
    },
    actions() {
      return {
        [ACTION_EDIT]: {
          href: this.project.editPath,
        },
        [ACTION_DELETE]: {
          action: this.onActionDelete,
        },
      };
    },
    hasActions() {
      return this.project.availableActions?.length;
    },
    hasActionDelete() {
      return this.project.availableActions?.includes(ACTION_DELETE);
    },
    timestampText() {
      return this.$options.i18n[this.timestampType];
    },
    timestamp() {
      return this.project[this.timestampType];
    },
  },
  methods: {
    topicPath(topic) {
      return `/explore/projects/topics/${encodeURIComponent(topic)}`;
    },
    topicTitle(topic) {
      return truncate(topic, MAX_TOPIC_TITLE_LENGTH);
    },
    topicTooltipTitle(topic) {
      // Matches conditional in app/assets/javascripts/lib/utils/text_utility.js#L88
      if (topic.length - 1 > MAX_TOPIC_TITLE_LENGTH) {
        return topic;
      }

      return null;
    },
    onActionDelete() {
      this.isDeleteModalVisible = true;
    },
    async onDeleteModalPrimary() {
      this.isDeleteLoading = true;

      try {
        await deleteProject(this.project.id, deleteParams(this.project));
        this.$emit('delete-complete');
        renderDeleteSuccessToast(this.project, this.$options.i18n.project);
      } catch (error) {
        createAlert({ message: this.$options.i18n.deleteErrorMessage, error, captureError: true });
      } finally {
        this.isDeleteLoading = false;
      }
    },
  },
};
</script>

<template>
  <li class="projects-list-item gl-border-b gl-flex gl-py-5">
    <div class="gl-grow md:gl-flex">
      <div class="gl-flex gl-grow gl-items-start">
        <div v-if="showProjectIcon" class="gl-mr-3 gl-flex gl-h-9 gl-shrink-0 gl-items-center">
          <gl-icon class="gl-text-secondary" name="project" />
        </div>
        <gl-avatar-labeled
          :entity-id="project.id"
          :entity-name="project.name"
          :label="project.name"
          :label-link="project.webUrl"
          :src="project.avatarUrl"
          shape="rect"
          :size="48"
        >
          <template #meta>
            <div class="gl-px-2">
              <div class="-gl-mx-2 gl-flex gl-flex-wrap gl-items-center">
                <div class="gl-px-2">
                  <gl-icon
                    v-if="visibility"
                    v-gl-tooltip="visibilityTooltip"
                    :name="visibilityIcon"
                    class="gl-text-secondary"
                  />
                </div>
                <div class="gl-px-2">
                  <gl-badge
                    v-if="shouldShowAccessLevel"
                    class="gl-block"
                    data-testid="access-level-badge"
                    >{{ accessLevelLabel }}</gl-badge
                  >
                </div>
              </div>
            </div>
          </template>
          <gl-truncate-text
            v-if="project.descriptionHtml"
            :lines="2"
            :mobile-lines="2"
            :show-more-text="$options.i18n.showMore"
            :show-less-text="$options.i18n.showLess"
            :toggle-button-props="$options.truncateTextToggleButtonProps"
            class="gl-mt-2 gl-max-w-88"
          >
            <div
              v-safe-html="project.descriptionHtml"
              class="md gl-text-sm gl-text-secondary"
              data-testid="project-description"
            ></div>
          </gl-truncate-text>
          <div v-if="hasTopics" class="gl-mt-3" data-testid="project-topics">
            <div
              class="-gl-mx-2 -gl-my-2 gl-inline-flex gl-w-full gl-flex-wrap gl-items-center gl-text-base gl-font-normal"
            >
              <span class="gl-p-2 gl-text-sm gl-text-secondary">{{ $options.i18n.topics }}:</span>
              <div v-for="topic in visibleTopics" :key="topic" class="gl-p-2">
                <gl-badge v-gl-tooltip="topicTooltipTitle(topic)" :href="topicPath(topic)">
                  {{ topicTitle(topic) }}
                </gl-badge>
              </div>
              <template v-if="popoverTopics.length">
                <div
                  :id="topicsPopoverTarget"
                  class="gl-p-2 gl-text-sm gl-text-secondary"
                  role="button"
                  tabindex="0"
                >
                  <gl-sprintf :message="$options.i18n.topicsPopoverTargetText">
                    <template #count>{{ popoverTopics.length }}</template>
                  </gl-sprintf>
                </div>
                <gl-popover :target="topicsPopoverTarget" :title="$options.i18n.moreTopics">
                  <div class="-gl-mx-2 -gl-my-2 gl-text-base gl-font-normal">
                    <div v-for="topic in popoverTopics" :key="topic" class="gl-inline-block gl-p-2">
                      <gl-badge v-gl-tooltip="topicTooltipTitle(topic)" :href="topicPath(topic)">
                        {{ topicTitle(topic) }}
                      </gl-badge>
                    </div>
                  </div>
                </gl-popover>
              </template>
            </div>
          </div>
        </gl-avatar-labeled>
      </div>
      <div
        class="gl-mt-3 gl-shrink-0 gl-flex-col gl-items-end md:gl-mt-0 md:gl-flex md:gl-pl-0"
        :class="showProjectIcon ? 'gl-pl-12' : 'gl-pl-10'"
      >
        <div class="gl-flex gl-items-center gl-gap-x-3 md:gl-h-9">
          <project-list-item-inactive-badge :project="project" />
          <gl-link
            v-gl-tooltip="$options.i18n.stars"
            :href="starsHref"
            :aria-label="$options.i18n.stars"
            class="gl-text-secondary"
          >
            <gl-icon name="star-o" />
            <span>{{ starCount }}</span>
          </gl-link>
          <gl-link
            v-if="isForkingEnabled"
            v-gl-tooltip="$options.i18n.forks"
            :href="forksHref"
            :aria-label="$options.i18n.forks"
            class="gl-text-secondary"
          >
            <gl-icon name="fork" />
            <span>{{ forksCount }}</span>
          </gl-link>
          <gl-link
            v-if="isMergeRequestsEnabled"
            v-gl-tooltip="$options.i18n.mergeRequests"
            :href="mergeRequestsHref"
            :aria-label="$options.i18n.mergeRequests"
            class="gl-text-secondary"
          >
            <gl-icon name="merge-request" />
            <span>{{ openMergeRequestsCount }}</span>
          </gl-link>
          <gl-link
            v-if="isIssuesEnabled"
            v-gl-tooltip="$options.i18n.issues"
            :href="issuesHref"
            :aria-label="$options.i18n.issues"
            class="gl-text-secondary"
          >
            <gl-icon name="issues" />
            <span>{{ openIssuesCount }}</span>
          </gl-link>
        </div>
        <div
          v-if="timestamp"
          class="gl-mt-3 gl-whitespace-nowrap gl-text-sm gl-text-secondary md:-gl-mt-2"
        >
          <span>{{ timestampText }}</span>
          <time-ago-tooltip :time="timestamp" />
        </div>
      </div>
    </div>
    <div class="gl-ml-3 gl-flex gl-h-9 gl-items-center">
      <list-actions
        v-if="hasActions"
        :actions="actions"
        :available-actions="project.availableActions"
      />
    </div>

    <delete-modal
      v-if="hasActionDelete"
      v-model="isDeleteModalVisible"
      :confirm-phrase="project.name"
      :is-fork="project.isForked"
      :confirm-loading="isDeleteLoading"
      :merge-requests-count="openMergeRequestsCount"
      :issues-count="openIssuesCount"
      :forks-count="forksCount"
      :stars-count="starCount"
      @primary="onDeleteModalPrimary"
    >
      <template #modal-footer
        ><project-list-item-delayed-deletion-modal-footer :project="project"
      /></template>
    </delete-modal>
  </li>
</template>
