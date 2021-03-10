<script>
/*
 * This is tightly coupled to projects/issues/_issue.html.haml,
 * any changes done to the haml need to be reflected here.
 */

// TODO: need to move this component to graphql - https://gitlab.com/gitlab-org/gitlab/-/issues/221246
import jiraLogo from '@gitlab/svgs/dist/illustrations/logos/jira.svg';
import {
  GlLink,
  GlTooltipDirective as GlTooltip,
  GlSprintf,
  GlLabel,
  GlIcon,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { escape, isNumber } from 'lodash';
import { isScopedLabel } from '~/lib/utils/common_utils';
import {
  dateInWords,
  formatDate,
  getDayDifference,
  getTimeago,
  timeFor,
  newDateAsLocaleTime,
} from '~/lib/utils/datetime_utility';
import { convertToCamelCase } from '~/lib/utils/text_utility';
import { mergeUrlParams, setUrlFragment, isExternal } from '~/lib/utils/url_utility';
import { sprintf, __ } from '~/locale';
import initUserPopovers from '~/user_popovers';
import IssueAssignees from '~/vue_shared/components/issue/issue_assignees.vue';

export default {
  i18n: {
    openedAgo: __('created %{timeAgoString} by %{user}'),
    openedAgoJira: __('created %{timeAgoString} by %{user} in Jira'),
    openedAgoServiceDesk: __('created %{timeAgoString} by %{email} via %{user}'),
  },
  components: {
    IssueAssignees,
    GlLink,
    GlLabel,
    GlIcon,
    GlSprintf,
    IssueHealthStatus: () =>
      import('ee_component/related_items_tree/components/issue_health_status.vue'),
  },
  directives: {
    GlTooltip,
    SafeHtml,
  },
  inject: ['scopedLabelsAvailable'],
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
    hasWeight() {
      return isNumber(this.issuable.weight);
    },
    dueDate() {
      return this.issuable.due_date ? newDateAsLocaleTime(this.issuable.due_date) : undefined;
    },
    dueDateWords() {
      return this.dueDate ? dateInWords(this.dueDate, true) : undefined;
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
    webUrl() {
      return this.issuable.gitlab_web_url || this.issuable.web_url;
    },
    isIssuableUrlExternal() {
      return isExternal(this.webUrl);
    },
    linkTarget() {
      return this.isIssuableUrlExternal ? '_blank' : null;
    },
    issueCreatedToday() {
      return getDayDifference(new Date(this.issuable.created_at), new Date()) < 1;
    },
    labelIdsString() {
      return JSON.stringify(this.issuable.labels.map((l) => l.id));
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
    issuableMeta() {
      return [
        {
          key: 'merge-requests',
          visible: this.issuable.merge_requests_count > 0,
          value: this.issuable.merge_requests_count,
          title: __('Related merge requests'),
          dataTestId: 'merge-requests',
          class: 'js-merge-requests',
          icon: 'merge-request',
        },
        {
          key: 'upvotes',
          visible: this.issuable.upvotes > 0,
          value: this.issuable.upvotes,
          title: __('Upvotes'),
          dataTestId: 'upvotes',
          class: 'js-upvotes issuable-upvotes',
          icon: 'thumb-up',
        },
        {
          key: 'downvotes',
          visible: this.issuable.downvotes > 0,
          value: this.issuable.downvotes,
          title: __('Downvotes'),
          dataTestId: 'downvotes',
          class: 'js-downvotes issuable-downvotes',
          icon: 'thumb-down',
        },
        {
          key: 'blocking-issues',
          visible: this.issuable.blocking_issues_count > 0,
          value: this.issuable.blocking_issues_count,
          title: __('Blocking issues'),
          dataTestId: 'blocking-issues',
          href: setUrlFragment(this.webUrl, 'related-issues'),
          icon: 'issue-block',
        },
        {
          key: 'comments-count',
          visible: !this.isJiraIssue,
          value: this.issuable.user_notes_count,
          title: __('Comments'),
          dataTestId: 'notes-count',
          href: setUrlFragment(this.webUrl, 'notes'),
          class: { 'no-comments': !this.issuable.user_notes_count, 'issuable-comments': true },
          icon: 'comments',
        },
      ];
    },
    healthStatus() {
      return convertToCamelCase(this.issuable.health_status);
    },
    openedMessage() {
      if (this.isJiraIssue) return this.$options.i18n.openedAgoJira;
      if (this.issuable.service_desk_reply_to) return this.$options.i18n.openedAgoServiceDesk;
      return this.$options.i18n.openedAgo;
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
      if (this.isJiraIssue) {
        return this.issuableLink({ 'labels[]': name });
      }

      return this.issuableLink({ 'label_name[]': name });
    },
    onSelect(ev) {
      this.$emit('select', {
        issuable: this.issuable,
        selected: ev.target.checked,
      });
    },
    issuableMetaComponent(href) {
      return href ? 'gl-link' : 'span';
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
    :data-url="webUrl"
    data-qa-selector="issue_container"
    :data-qa-issue-title="issuable.title"
  >
    <div class="gl-display-flex">
      <!-- Bulk edit checkbox -->
      <div v-if="isBulkEditing" class="gl-mr-3">
        <input
          :id="`selected_issue_${issuable.id}`"
          :checked="selected"
          class="selected-issuable"
          type="checkbox"
          :data-id="issuable.id"
          @input="onSelect"
        />
      </div>

      <!-- Issuable info container -->
      <!-- Issuable main info -->
      <div class="gl-flex-grow-1">
        <div class="title">
          <span class="issue-title-text">
            <gl-icon
              v-if="issuable.confidential"
              v-gl-tooltip
              name="eye-slash"
              class="gl-vertical-align-text-bottom"
              :size="16"
              :title="$options.confidentialTooltipText"
              :aria-label="$options.confidentialTooltipText"
            />
            <gl-link
              :href="webUrl"
              :target="linkTarget"
              data-testid="issuable-title"
              data-qa-selector="issue_link"
            >
              {{ issuable.title }}
              <gl-icon
                v-if="isIssuableUrlExternal"
                name="external-link"
                class="gl-vertical-align-text-bottom gl-ml-2"
              />
            </gl-link>
          </span>
          <span
            v-if="issuable.has_tasks"
            class="gl-ml-2 task-status gl-display-none d-sm-inline-block"
            >{{ issuable.task_status }}</span
          >
        </div>

        <div class="issuable-info">
          <span class="js-ref-path gl-mr-4 mr-sm-0">
            <span
              v-if="isJiraIssue"
              v-safe-html="jiraLogo"
              class="svg-container jira-logo-container"
              data-testid="jira-logo"
            ></span>
            {{ referencePath }}
          </span>

          <span data-testid="openedByMessage" class="gl-display-none d-sm-inline-block gl-mr-4">
            &middot;
            <gl-sprintf :message="openedMessage">
              <template #timeAgoString>
                <span>{{ issuableCreatedAt }}</span>
              </template>
              <template #user>
                <gl-link
                  ref="openedAgoByContainer"
                  v-bind="popoverDataAttrs"
                  :href="issuableAuthor.web_url"
                  :target="linkTarget"
                  >{{ issuableAuthor.name }}</gl-link
                >
              </template>
              <template #email>
                <span>{{ issuable.service_desk_reply_to }}</span>
              </template>
            </gl-sprintf>
          </span>

          <gl-link
            v-if="issuable.milestone"
            v-gl-tooltip
            class="gl-display-none d-sm-inline-block gl-mr-4 js-milestone milestone"
            :href="milestoneLink"
            :title="milestoneTooltipText"
          >
            <gl-icon name="clock" class="s16 gl-vertical-align-text-bottom" />
            {{ issuable.milestone.title }}
          </gl-link>

          <span
            v-if="dueDate"
            v-gl-tooltip
            class="gl-display-none d-sm-inline-block gl-mr-4 js-due-date"
            :class="{ cred: isOverdue }"
            :title="__('Due date')"
          >
            <gl-icon name="calendar" />
            {{ dueDateWords }}
          </span>

          <span
            v-if="hasWeight"
            v-gl-tooltip
            :title="__('Weight')"
            class="gl-display-none d-sm-inline-block gl-mr-4"
            data-testid="weight"
            data-qa-selector="issuable_weight_content"
          >
            <gl-icon name="weight" class="align-text-bottom" />
            {{ issuable.weight }}
          </span>

          <issue-health-status
            v-if="issuable.health_status"
            :health-status="healthStatus"
            class="gl-mr-4 issuable-tag-valign"
          />

          <gl-label
            v-for="label in issuable.labels"
            :key="label.id"
            data-qa-selector="issuable-label"
            :target="labelHref(label)"
            :background-color="label.color"
            :description="label.description"
            :color="label.text_color"
            :title="label.name"
            :scoped="isScoped(label)"
            size="sm"
            class="gl-mr-2 issuable-tag-valign"
            >{{ label.name }}</gl-label
          >
        </div>
      </div>

      <!-- Issuable meta -->
      <div
        class="gl-flex-shrink-0 gl-display-flex gl-flex-direction-column align-items-end gl-justify-content-center"
      >
        <div class="controls gl-display-flex">
          <span v-if="isJiraIssue" data-testid="issuable-status">{{ issuable.status }}</span>
          <span v-else-if="isClosed" class="issuable-status">{{ __('CLOSED') }}</span>

          <issue-assignees
            :assignees="issuable.assignees"
            class="gl-align-items-center gl-display-flex gl-ml-3"
            :icon-size="16"
            img-css-classes="gl-mr-2!"
            :max-visible="4"
          />

          <template v-for="meta in issuableMeta">
            <span
              v-if="meta.visible"
              :key="meta.key"
              v-gl-tooltip
              class="gl-display-none gl-sm-display-flex gl-align-items-center gl-ml-3"
              :class="meta.class"
              :data-testid="meta.dataTestId"
              :title="meta.title"
            >
              <component :is="issuableMetaComponent(meta.href)" :href="meta.href">
                <gl-icon v-if="meta.icon" :name="meta.icon" />
                {{ meta.value }}
              </component>
            </span>
          </template>
        </div>
        <div v-gl-tooltip class="issuable-updated-at" :title="updatedDateString">
          {{ updatedDateAgo }}
        </div>
      </div>
    </div>
  </li>
</template>
