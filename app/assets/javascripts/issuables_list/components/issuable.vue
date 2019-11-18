<script>
/*
 * This is tightly coupled to projects/issues/_issue.html.haml,
 * any changes done to the haml need to be reflected here.
 */
import { escape, isNumber } from 'underscore';
import { GlLink, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
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
import Icon from '~/vue_shared/components/icon.vue';
import IssueAssignees from '~/vue_shared/components/issue/issue_assignees.vue';

const ISSUE_TOKEN = '#';

export default {
  components: {
    Icon,
    IssueAssignees,
    GlLink,
  },
  directives: {
    GlTooltip,
  },
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
  computed: {
    milestoneLink() {
      const { title } = this.issuable.milestone;

      return this.issuableLink({ milestone_title: title });
    },
    hasLabels() {
      return Boolean(this.issuable.labels && this.issuable.labels.length);
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
    openedAgoByString() {
      const { author, created_at } = this.issuable;

      return sprintf(
        __('opened %{timeAgoString} by %{user}'),
        {
          timeAgoString: escape(getTimeago().format(created_at)),
          user: `<a href="${escape(author.web_url)}"
            data-user-id=${escape(author.id)}
            data-username=${escape(author.username)}
            data-name=${escape(author.name)}
            data-avatar-url="${escape(author.avatar_url)}">
            ${escape(author.name)}
          </a>`,
        },
        false,
      );
    },
    referencePath() {
      // TODO: The API should return the reference path (it doesn't now) https://gitlab.com/gitlab-org/gitlab/issues/31301
      return `${ISSUE_TOKEN}${this.issuable.iid}`;
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
          faicon: 'fa-thumbs-up',
        },
        {
          key: 'downvotes',
          value: this.issuable.downvotes,
          title: __('Downvotes'),
          class: 'js-downvotes',
          faicon: 'fa-thumbs-down',
        },
      ];
    },
  },
  mounted() {
    // TODO: Refactor user popover to use its own component instead of
    // spawning event listeners on Vue-rendered elements.
    initUserPopovers([this.$refs.openedAgoByContainer.querySelector('a')]);
  },
  methods: {
    labelStyle(label) {
      return {
        backgroundColor: label.color,
        color: label.text_color,
      };
    },
    issuableLink(params) {
      return mergeUrlParams(params, this.baseUrl);
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
            <gl-link :href="issuable.web_url">{{ issuable.title }}</gl-link>
          </span>
          <span v-if="issuable.has_tasks" class="ml-1 task-status d-none d-sm-inline-block">{{
            issuable.task_status
          }}</span>
        </div>

        <div class="issuable-info">
          <span>{{ referencePath }}</span>

          <span class="d-none d-sm-inline-block mr-1">
            &middot;
            <span ref="openedAgoByContainer" v-html="openedAgoByString"></span>
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

          <span v-if="hasLabels" class="js-labels">
            <gl-link
              v-for="label in issuable.labels"
              :key="label.id"
              class="label-link mr-1"
              :href="labelHref(label)"
            >
              <span
                v-gl-tooltip
                class="badge color-label"
                :style="labelStyle(label)"
                :title="label.description"
                >{{ label.name }}</span
              >
            </gl-link>
          </span>

          <span
            v-if="hasWeight"
            v-gl-tooltip
            :title="__('Weight')"
            class="d-none d-sm-inline-block js-weight"
          >
            <icon name="weight" class="align-text-bottom" />
            {{ issuable.weight }}
          </span>
        </div>
      </div>

      <!-- Issuable meta -->
      <div class="flex-shrink-0 d-flex flex-column align-items-end justify-content-center">
        <div class="controls d-flex">
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
              :class="['d-none d-sm-inline-block ml-2', meta.class]"
              :title="meta.title"
            >
              <icon v-if="meta.icon" :name="meta.icon" />
              <i v-else :class="['fa', meta.faicon]"></i>
              {{ meta.value }}
            </span>
          </template>

          <gl-link
            v-gl-tooltip
            class="ml-2 js-notes"
            :href="`${issuable.web_url}#notes`"
            :title="__('Comments')"
            :class="{ 'no-comments': hasNoComments }"
          >
            <i class="fa fa-comments"></i>
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
