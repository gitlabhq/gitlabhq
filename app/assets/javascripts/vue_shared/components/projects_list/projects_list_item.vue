<script>
import {
  GlAvatarLabeled,
  GlIcon,
  GlLink,
  GlBadge,
  GlTooltipDirective,
  GlPopover,
  GlSprintf,
} from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';

import { VISIBILITY_TYPE_ICON, PROJECT_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS } from '~/access_level/constants';
import { FEATURABLE_ENABLED } from '~/featurable/constants';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import { __ } from '~/locale';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import { truncate } from '~/lib/utils/text_utility';
import SafeHtml from '~/vue_shared/directives/safe_html';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import DeleteModal from '~/projects/components/shared/delete_modal.vue';

const MAX_TOPICS_TO_SHOW = 3;
const MAX_TOPIC_TITLE_LENGTH = 15;

export default {
  i18n: {
    stars: __('Stars'),
    forks: __('Forks'),
    issues: __('Issues'),
    archived: __('Archived'),
    topics: __('Topics'),
    topicsPopoverTargetText: __('+ %{count} more'),
    moreTopics: __('More topics'),
    updated: __('Updated'),
    actions: __('Actions'),
  },
  avatarSize: { default: 32, md: 48 },
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
  components: {
    GlAvatarLabeled,
    GlIcon,
    UserAccessRoleBadge,
    GlLink,
    GlBadge,
    GlPopover,
    GlSprintf,
    TimeAgoTooltip,
    DeleteModal,
    ListActions,
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
     *   permissions: {
     *     projectAccess: { accessLevel: 50 };
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
  },
  data() {
    return {
      topicsPopoverTarget: uniqueId('project-topics-popover-'),
      isDeleteModalVisible: false,
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
      return this.project.permissions?.projectAccess?.accessLevel;
    },
    accessLevelLabel() {
      return ACCESS_LEVEL_LABELS[this.accessLevel];
    },
    shouldShowAccessLevel() {
      return this.accessLevel !== undefined;
    },
    starsHref() {
      return `${this.project.webUrl}/-/starrers`;
    },
    forksHref() {
      return `${this.project.webUrl}/-/forks`;
    },
    issuesHref() {
      return `${this.project.webUrl}/-/issues`;
    },
    isForkingEnabled() {
      return (
        this.project.forkingAccessLevel === FEATURABLE_ENABLED &&
        this.project.forksCount !== undefined
      );
    },
    isIssuesEnabled() {
      return this.project.issuesAccessLevel === FEATURABLE_ENABLED;
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
  },
};
</script>

<template>
  <li class="projects-list-item gl-py-5 gl-border-b gl-display-flex gl-align-items-flex-start">
    <div class="gl-md-display-flex gl-align-items-center gl-flex-grow-1">
      <div class="gl-display-flex gl-flex-grow-1">
        <gl-icon
          v-if="showProjectIcon"
          class="gl-mr-3 gl-mt-3 gl-md-mt-5 gl-flex-shrink-0 gl-text-secondary"
          name="project"
        />
        <gl-avatar-labeled
          :entity-id="project.id"
          :entity-name="project.name"
          :label="project.name"
          :label-link="project.webUrl"
          shape="rect"
          :size="$options.avatarSize"
        >
          <template #meta>
            <div class="gl-px-2">
              <div class="gl-mx-n2 gl-display-flex gl-align-items-center gl-flex-wrap">
                <div class="gl-px-2">
                  <gl-icon
                    v-if="visibility"
                    v-gl-tooltip="visibilityTooltip"
                    :name="visibilityIcon"
                    class="gl-text-secondary"
                  />
                </div>
                <div class="gl-px-2">
                  <user-access-role-badge v-if="shouldShowAccessLevel">{{
                    accessLevelLabel
                  }}</user-access-role-badge>
                </div>
              </div>
            </div>
          </template>
          <div
            v-if="project.descriptionHtml"
            v-safe-html:[$options.safeHtmlConfig]="project.descriptionHtml"
            class="gl-font-sm gl-overflow-hidden gl-line-height-20 description md"
            data-testid="project-description"
          ></div>
          <div v-if="hasTopics" class="gl-mt-3" data-testid="project-topics">
            <div
              class="gl-w-full gl-display-inline-flex gl-flex-wrap gl-font-base gl-font-weight-normal gl-align-items-center gl-mx-n2 gl-my-n2"
            >
              <span class="gl-p-2 gl-text-secondary">{{ $options.i18n.topics }}:</span>
              <div v-for="topic in visibleTopics" :key="topic" class="gl-p-2">
                <gl-badge v-gl-tooltip="topicTooltipTitle(topic)" :href="topicPath(topic)">
                  {{ topicTitle(topic) }}
                </gl-badge>
              </div>
              <template v-if="popoverTopics.length">
                <div
                  :id="topicsPopoverTarget"
                  class="gl-p-2 gl-text-secondary"
                  role="button"
                  tabindex="0"
                >
                  <gl-sprintf :message="$options.i18n.topicsPopoverTargetText">
                    <template #count>{{ popoverTopics.length }}</template>
                  </gl-sprintf>
                </div>
                <gl-popover :target="topicsPopoverTarget" :title="$options.i18n.moreTopics">
                  <div class="gl-font-base gl-font-weight-normal gl-mx-n2 gl-my-n2">
                    <div
                      v-for="topic in popoverTopics"
                      :key="topic"
                      class="gl-p-2 gl-display-inline-block"
                    >
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
        class="gl-md-display-flex gl-flex-direction-column gl-align-items-flex-end gl-flex-shrink-0 gl-mt-3 gl-md-pl-0 gl-md-mt-0"
        :class="showProjectIcon ? 'gl-pl-11' : 'gl-pl-8'"
      >
        <div class="gl-display-flex gl-align-items-center gl-gap-x-3">
          <gl-badge v-if="project.archived" variant="warning">{{
            $options.i18n.archived
          }}</gl-badge>
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
          v-if="project.updatedAt"
          class="gl-font-sm gl-white-space-nowrap gl-text-secondary gl-mt-3"
        >
          <span>{{ $options.i18n.updated }}</span>
          <time-ago-tooltip :time="project.updatedAt" />
        </div>
      </div>
    </div>
    <list-actions
      v-if="hasActions"
      class="gl-ml-3 gl-md-align-self-center"
      :actions="actions"
      :available-actions="project.availableActions"
    />

    <delete-modal
      v-if="hasActionDelete"
      v-model="isDeleteModalVisible"
      :confirm-phrase="project.name"
      :is-fork="project.isForked"
      :issues-count="openIssuesCount"
      :forks-count="forksCount"
      :stars-count="starCount"
      @primary="$emit('delete', project)"
    />
  </li>
</template>
