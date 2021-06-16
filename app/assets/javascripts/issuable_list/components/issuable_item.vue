<script>
import { GlLink, GlIcon, GlLabel, GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { differenceInSeconds, getTimeago, SECONDS_IN_DAY } from '~/lib/utils/datetime_utility';
import { isExternal, setUrlFragment } from '~/lib/utils/url_utility';
import { __, n__, sprintf } from '~/locale';
import IssuableAssignees from '~/vue_shared/components/issue/issue_assignees.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    GlLink,
    GlIcon,
    GlLabel,
    GlFormCheckbox,
    IssuableAssignees,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    issuableSymbol: {
      type: String,
      required: true,
    },
    issuable: {
      type: Object,
      required: true,
    },
    enableLabelPermalinks: {
      type: Boolean,
      required: true,
    },
    labelFilterParam: {
      type: String,
      required: false,
      default: 'label_name',
    },
    showCheckbox: {
      type: Boolean,
      required: true,
    },
    checked: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    issuableId() {
      return getIdFromGraphQLId(this.issuable.id);
    },
    createdInPastDay() {
      const createdSecondsAgo = differenceInSeconds(new Date(this.issuable.createdAt), new Date());
      return createdSecondsAgo < SECONDS_IN_DAY;
    },
    author() {
      return this.issuable.author;
    },
    webUrl() {
      return this.issuable.gitlabWebUrl || this.issuable.webUrl;
    },
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
    isIssuableUrlExternal() {
      return isExternal(this.webUrl);
    },
    labels() {
      return this.issuable.labels?.nodes || this.issuable.labels || [];
    },
    labelIdsString() {
      return JSON.stringify(this.labels.map((label) => getIdFromGraphQLId(label.id)));
    },
    assignees() {
      return this.issuable.assignees?.nodes || this.issuable.assignees || [];
    },
    createdAt() {
      return sprintf(__('created %{timeAgo}'), {
        timeAgo: getTimeago().format(this.issuable.createdAt),
      });
    },
    updatedAt() {
      return sprintf(__('updated %{timeAgo}'), {
        timeAgo: getTimeago().format(this.issuable.updatedAt),
      });
    },
    issuableTitleProps() {
      if (this.isIssuableUrlExternal) {
        return {
          target: '_blank',
        };
      }
      return {};
    },
    taskStatus() {
      const { completedCount, count } = this.issuable.taskCompletionStatus || {};
      if (!count) {
        return undefined;
      }

      return sprintf(
        n__(
          '%{completedCount} of %{count} task completed',
          '%{completedCount} of %{count} tasks completed',
          count,
        ),
        { completedCount, count },
      );
    },
    notesCount() {
      return this.issuable.userDiscussionsCount ?? this.issuable.userNotesCount;
    },
    showDiscussions() {
      return typeof this.notesCount === 'number';
    },
    showIssuableMeta() {
      return Boolean(
        this.hasSlotContents('status') || this.showDiscussions || this.issuable.assignees,
      );
    },
    issuableNotesLink() {
      return setUrlFragment(this.webUrl, 'notes');
    },
  },
  methods: {
    hasSlotContents(slotName) {
      return Boolean(this.$slots[slotName]);
    },
    scopedLabel(label) {
      return isScopedLabel(label);
    },
    labelTitle(label) {
      return label.title || label.name;
    },
    labelTarget(label) {
      if (this.enableLabelPermalinks) {
        const value = encodeURIComponent(this.labelTitle(label));
        return `?${this.labelFilterParam}[]=${value}`;
      }
      return '#';
    },
    /**
     * This is needed as an independent method since
     * when user changes current page, `$refs.authorLink`
     * will be null until next page results are loaded & rendered.
     */
    getAuthorPopoverTarget() {
      if (this.$refs.authorLink) {
        return this.$refs.authorLink.$el;
      }
      return '';
    },
  },
};
</script>

<template>
  <li
    :id="`issuable_${issuableId}`"
    class="issue gl-px-5!"
    :class="{ closed: issuable.closedAt, today: createdInPastDay }"
    :data-labels="labelIdsString"
  >
    <div class="issuable-info-container">
      <div v-if="showCheckbox" class="issue-check">
        <gl-form-checkbox
          class="gl-mr-0"
          :checked="checked"
          :data-id="issuableId"
          @input="$emit('checked-input', $event)"
        >
          <span class="gl-sr-only">{{ issuable.title }}</span>
        </gl-form-checkbox>
      </div>
      <div class="issuable-main-info">
        <div data-testid="issuable-title" class="issue-title title">
          <span class="issue-title-text" dir="auto">
            <gl-icon
              v-if="issuable.confidential"
              v-gl-tooltip
              name="eye-slash"
              :title="__('Confidential')"
              :aria-label="__('Confidential')"
            />
            <gl-link :href="webUrl" v-bind="issuableTitleProps">
              {{ issuable.title
              }}<gl-icon v-if="isIssuableUrlExternal" name="external-link" class="gl-ml-2"
            /></gl-link>
          </span>
          <span
            v-if="taskStatus"
            class="task-status gl-display-none gl-sm-display-inline-block! gl-ml-3"
            data-testid="task-status"
          >
            {{ taskStatus }}
          </span>
        </div>
        <div class="issuable-info">
          <slot v-if="hasSlotContents('reference')" name="reference"></slot>
          <span v-else data-testid="issuable-reference" class="issuable-reference"
            >{{ issuableSymbol }}{{ issuable.iid }}</span
          >
          <span class="issuable-authored gl-display-none gl-sm-display-inline-block! gl-mr-3">
            &middot;
            <span
              v-gl-tooltip:tooltipcontainer.bottom
              data-testid="issuable-created-at"
              :title="tooltipTitle(issuable.createdAt)"
              >{{ createdAt }}</span
            >
            {{ __('by') }}
            <slot v-if="hasSlotContents('author')" name="author"></slot>
            <gl-link
              v-else
              :data-user-id="authorId"
              :data-username="author.username"
              :data-name="author.name"
              :data-avatar-url="author.avatarUrl"
              :href="author.webUrl"
              data-testid="issuable-author"
              class="author-link js-user-link"
            >
              <span class="author">{{ author.name }}</span>
            </gl-link>
          </span>
          <slot name="timeframe"></slot>
          &nbsp;
          <gl-label
            v-for="(label, index) in labels"
            :key="index"
            :background-color="label.color"
            :title="labelTitle(label)"
            :description="label.description"
            :scoped="scopedLabel(label)"
            :target="labelTarget(label)"
            :class="{ 'gl-ml-2': index }"
            size="sm"
          />
        </div>
      </div>
      <div class="issuable-meta">
        <ul v-if="showIssuableMeta" class="controls">
          <li v-if="hasSlotContents('status')" class="issuable-status">
            <slot name="status"></slot>
          </li>
          <li v-if="assignees.length" class="gl-display-flex">
            <issuable-assignees
              :assignees="assignees"
              :icon-size="16"
              :max-visible="4"
              img-css-classes="gl-mr-2!"
              class="gl-align-items-center gl-display-flex gl-ml-3"
            />
          </li>
          <slot name="statistics"></slot>
          <li
            v-if="showDiscussions"
            data-testid="issuable-discussions"
            class="issuable-comments gl-display-none gl-sm-display-block"
          >
            <gl-link
              v-gl-tooltip:tooltipcontainer.top
              :title="__('Comments')"
              :href="issuableNotesLink"
              :class="{ 'no-comments': !notesCount }"
              class="gl-reset-color!"
            >
              <gl-icon name="comments" />
              {{ notesCount }}
            </gl-link>
          </li>
        </ul>
        <div
          data-testid="issuable-updated-at"
          class="float-right issuable-updated-at gl-display-none gl-sm-display-inline-block"
        >
          <span
            v-gl-tooltip:tooltipcontainer.bottom
            :title="tooltipTitle(issuable.updatedAt)"
            class="issuable-updated-at"
            >{{ updatedAt }}</span
          >
        </div>
      </div>
    </div>
  </li>
</template>
