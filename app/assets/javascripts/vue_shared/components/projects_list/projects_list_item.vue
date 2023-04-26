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
  },
  components: {
    GlAvatarLabeled,
    GlIcon,
    UserAccessRoleBadge,
    GlLink,
    GlBadge,
    GlPopover,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
     */
    project: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      topicsPopoverTarget: uniqueId('project-topics-popover-'),
    };
  },
  computed: {
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.project.visibility];
    },
    visibilityTooltip() {
      return PROJECT_VISIBILITY_TYPE[this.project.visibility];
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
  },
  methods: {
    numberToMetricPrefix,
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
  },
};
</script>

<template>
  <li class="gl-py-5 gl-md-display-flex gl-align-items-center gl-border-b">
    <gl-avatar-labeled
      class="gl-flex-grow-1"
      :entity-id="project.id"
      :entity-name="project.name"
      :label="project.name"
      :label-link="project.webUrl"
      shape="rect"
      :size="48"
    >
      <template #meta>
        <gl-icon
          v-gl-tooltip="visibilityTooltip"
          :name="visibilityIcon"
          class="gl-text-secondary gl-ml-3"
        />
        <user-access-role-badge v-if="shouldShowAccessLevel" class="gl-ml-3">{{
          accessLevelLabel
        }}</user-access-role-badge>
      </template>
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
    <div
      class="gl-md-display-flex gl-flex-direction-column gl-align-items-flex-end gl-flex-shrink-0 gl-mt-3 gl-md-mt-0"
    >
      <div class="gl-display-flex gl-align-items-center gl-gap-x-3">
        <gl-badge v-if="project.archived" variant="warning">{{ $options.i18n.archived }}</gl-badge>
        <gl-link
          v-gl-tooltip="$options.i18n.stars"
          :href="starsHref"
          :aria-label="$options.i18n.stars"
          class="gl-text-secondary"
        >
          <gl-icon name="star-o" />
          <span>{{ numberToMetricPrefix(project.starCount) }}</span>
        </gl-link>
        <gl-link
          v-if="isForkingEnabled"
          v-gl-tooltip="$options.i18n.forks"
          :href="forksHref"
          :aria-label="$options.i18n.forks"
          class="gl-text-secondary"
        >
          <gl-icon name="fork" />
          <span>{{ numberToMetricPrefix(project.forksCount) }}</span>
        </gl-link>
        <gl-link
          v-if="isIssuesEnabled"
          v-gl-tooltip="$options.i18n.issues"
          :href="issuesHref"
          :aria-label="$options.i18n.issues"
          class="gl-text-secondary"
        >
          <gl-icon name="issues" />
          <span>{{ numberToMetricPrefix(project.openIssuesCount) }}</span>
        </gl-link>
      </div>
    </div>
  </li>
</template>
