<script>
/*
 * This is tightly coupled to projects/issues/_issue.html.haml,
 * any changes done to the haml need to be reflected here.
 */

// TODO: need to move this component to graphql - https://gitlab.com/gitlab-org/gitlab/-/issues/221246
import { escape, isNumber } from 'lodash';
import { GlLink, GlTooltipDirective as GlTooltip, GlSprintf, GlLabel, GlIcon } from '@gitlab/ui';
import jiraLogo from '@gitlab/svgs/dist/illustrations/logos/jira.svg';
import {
  dateInWords,
  formatDate,
  getDayDifference,
  getTimeago,
  timeFor,
  newDateAsLocaleTime,
} from '~/lib/utils/datetime_utility';
import { sprintf, __ } from '~/locale';
import initUserPopovers from '~/user_popovers';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import IssueAssignees from '~/vue_shared/components/issue/issue_assignees.vue';
import { isScopedLabel } from '~/lib/utils/common_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  i18n: {
    openedAgo: __('opened %{timeAgoString} by %{user}'),
    openedAgoJira: __('opened %{timeAgoString} by %{user} in Jira'),
  },
  components: {
    IssueAssignees,
    GlLink,
    GlLabel,
    GlIcon,
    GlSprintf,
  },
  directives: {
    GlTooltip,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    issuable: {
      type: Object,
      required: true,
    },
    isBulkEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    selected: {
      type: Boolean,
      required: false,
      default: false,
    },
    baseUrl: {
      type: String,
      required: false,
      default() {
        return window.location.href;
      },
    },
  },
  data() {
    return {
      jiraLogo,
    };
  },
  computed: {
    milestoneLink() {
      const { title } = this.issuable.milestone;

      return this.issuableLink({ milestone_title: title });
    },
    scopedLabelsAvailable() {
      return this.glFeatures.scopedLabels;
    },
    hasWeight() {
      return isNumber(this.issuable.weight);
    },
    dueDate() {
      return this.issuable.due_date ? newDateAsLocaleTime(this.issuable.due_date) : undefined;
    },
    dueDateWords() {
      return this.dueDate ? dateInWords(this.dueDate, true) : undefined;
    },
    hasNoComments() {
      return !this.userNotesCount;
    },
    isOverdue() {
      return this.dueDate ? this.dueDate < new Date() : false;
    },
    isClosed() {
      return this.issuable.state === 'closed';
    },
    isJiraIssue() {
      return this.issuable.external_tracker === 'jira';
    },
    issueCreatedToday() {
      return getDayDifference(new Date(this.issuable.created_at), new Date()) < 1;
    },
    labelIdsString() {
      return JSON.stringify(this.issuable.labels.map(l => l.id));
    },
    milestoneDueDate() {
      const { due_date: dueDate } = this.issuable.milestone || {};

      return dueDate ? newDateAsLocaleTime(dueDate) : undefined;
    },
    milestoneTooltipText() {
      if (this.milestoneDueDate) {
        return sprintf(__('%{primary} (%{secondary})'), {
          primary: formatDate(this.milestoneDueDate, 'mmm d, yyyy'),
          secondary: timeFor(this.milestoneDueDate),
        });
      }
      return __('Milestone');
    },
    issuableAuthor() {
      return this.issuable.author;
    },
    issuableCreatedAt() {
      return getTimeago().format(this.issuable.created_at);
    },
    popoverDataAttrs() {
      const { id, username, name, avatar_url } = this.issuableAuthor;

      return {
        'data-user-id': id,
        'data-username': username,
        'data-name': name,
        'data-avatar-url': avatar_url,
      };
    },
    referencePath() {
      return this.issuable.references.relative;
    },
    updatedDateString() {
      return formatDate(new Date(this.issuable.updated_at), 'mmm d, yyyy h:MMtt');
    },
    updatedDateAgo() {
      // snake_case because it's the same i18n string as the HAML view
      return sprintf(__('updated %{time_ago}'), {
        time_ago: escape(getTimeago().format(this.issuable.updated_at)),
      });
    },
    userNotesCount() {
      return this.issuable.user_notes_count;
    },
    issuableMeta() {
      return [
        {
          key: 'merge-requests',
          value: this.issuable.merge_requests_count,
          title: __('Related merge requests'),
          class: 'js-merge-requests',
          icon: 'merge-request',
        },
        {
          key: 'upvotes',
          value: this.issuable.upvotes,
          title: __('Upvotes'),
          class: 'js-upvotes',
          icon: 'thumb-up',
        },
        {
          key: 'downvotes',
          value: this.issuable.downvotes,
          title: __('Downvotes'),
          class: 'js-downvotes',
          icon: 'thumb-down',
        },
      ];
    },
  },
  mounted() {
    // TODO: Refactor user popover to use its own component instead of
    // spawning event listeners on Vue-rendered elements.
    initUserPopovers([this.$refs.openedAgoByContainer.$el]);
  },
  methods: {
    issuableLink(params) {
      return mergeUrlParams(params, this.baseUrl);
    },
    isScoped({ name }) {
      return isScopedLabel({ title: name }) && this.scopedLabelsAvailable;
    },
    labelHref({ name }) {
      return this.issuableLink({ 'label_name[]': name });
    },
    onSelect(ev) {
      this.$emit('select', {
        issuable: this.issuable,
        selected: ev.target.checked,
      });
    },
  },

  confidentialTooltipText: __('Confidential'),
};
</script>
<template>
  <li
    :id="`issue_${issuable.id}`"
    class="issue"
    :class="{ today: issueCreatedToday, closed: isClosed }"
    :data-id="issuable.id"
    :data-labels="labelIdsString"
    :data-url="issuable.web_url"
  >
    <div class="d-flex">
      <!-- Bulk edit checkbox -->
      <div v-if="isBulkEditing" class="mr-2">
        <input
          :checked="selected"
          class="selected-issuable"
          type="checkbox"
          :data-id="issuable.id"
          @input="onSelect"
        />
      </div>

      <!-- Issuable info container -->
      <!-- Issuable main info -->
      <div class="flex-grow-1">
        <div class="title">
          <span class="issue-title-text">
            <i
              v-if="issuable.confidential"
              v-gl-tooltip
              class="fa fa-eye-slash"
              :title="$options.confidentialTooltipText"
              :aria-label="$options.confidentialTooltipText"
            ></i>
            <gl-link
              :href="issuable.web_url"
              :target="isJiraIssue ? '_blank' : null"
              data-testid="issuable-title"
            >
              {{ issuable.title }}
              <gl-icon
                v-if="isJiraIssue"
                name="external-link"
                class="gl-vertical-align-text-bottom"
              />
            </gl-link>
          </span>
          <span v-if="issuable.has_tasks" class="ml-1 task-status d-none d-sm-inline-block">
            {{ issuable.task_status }}
          </span>
        </div>

        <div class="issuable-info">
          <span class="js-ref-path">
            <span
              v-if="isJiraIssue"
              class="svg-container jira-logo-container"
              data-testid="jira-logo"
              v-html="jiraLogo"
            ></span>
            {{ referencePath }}
          </span>

          <span data-testid="openedByMessage" class="d-none d-sm-inline-block mr-1">
            &middot;
            <gl-sprintf
              :message="isJiraIssue ? $options.i18n.openedAgoJira : $options.i18n.openedAgo"
            >
              <template #timeAgoString>
                <span>{{ issuableCreatedAt }}</span>
              </template>
              <template #user>
                <gl-link
                  ref="openedAgoByContainer"
                  v-bind="popoverDataAttrs"
                  :href="issuableAuthor.web_url"
                >
                  {{ issuableAuthor.name }}
                </gl-link>
              </template>
            </gl-sprintf>
          </span>

          <gl-link
            v-if="issuable.milestone"
            v-gl-tooltip
            class="d-none d-sm-inline-block mr-1 js-milestone"
            :href="milestoneLink"
            :title="milestoneTooltipText"
          >
            <i class="fa fa-clock-o"></i>
            {{ issuable.milestone.title }}
          </gl-link>

          <span
            v-if="dueDate"
            v-gl-tooltip
            class="d-none d-sm-inline-block mr-1 js-due-date"
            :class="{ cred: isOverdue }"
            :title="__('Due date')"
          >
            <i class="fa fa-calendar"></i>
            {{ dueDateWords }}
          </span>

          <gl-label
            v-for="label in issuable.labels"
            :key="label.id"
            :target="labelHref(label)"
            :background-color="label.color"
            :description="label.description"
            :color="label.text_color"
            :title="label.name"
            :scoped="isScoped(label)"
            size="sm"
            class="mr-1"
            >{{ label.name }}</gl-label
          >

          <span
            v-if="hasWeight"
            v-gl-tooltip
            :title="__('Weight')"
            class="d-none d-sm-inline-block js-weight"
          >
            <gl-icon name="weight" class="align-text-bottom" />
            {{ issuable.weight }}
          </span>
        </div>
      </div>

      <!-- Issuable meta -->
      <div class="flex-shrink-0 d-flex flex-column align-items-end justify-content-center">
        <div class="controls d-flex">
          <span v-if="isJiraIssue">&nbsp;</span>
          <span v-if="isClosed" class="issuable-status">{{ __('CLOSED') }}</span>

          <issue-assignees
            :assignees="issuable.assignees"
            class="align-items-center d-flex ml-2"
            :icon-size="16"
            img-css-classes="mr-1"
            :max-visible="4"
          />

          <template v-for="meta in issuableMeta">
            <span
              v-if="meta.value"
              :key="meta.key"
              v-gl-tooltip
              :class="['d-none d-sm-inline-block ml-2 vertical-align-middle', meta.class]"
              :title="meta.title"
            >
              <gl-icon v-if="meta.icon" :name="meta.icon" />
              {{ meta.value }}
            </span>
          </template>

          <gl-link
            v-if="!isJiraIssue"
            v-gl-tooltip
            class="ml-2 js-notes"
            :href="`${issuable.web_url}#notes`"
            :title="__('Comments')"
            :class="{ 'no-comments': hasNoComments }"
          >
            <gl-icon name="comments" class="gl-vertical-align-text-bottom" />
            {{ userNotesCount }}
          </gl-link>
        </div>
        <div v-gl-tooltip class="issuable-updated-at" :title="updatedDateString">
          {{ updatedDateAgo }}
        </div>
      </div>
    </div>
  </li>
</template>
