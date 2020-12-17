<script>
import { GlLink, GlIcon, GlLabel, GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';

import { __, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { isScopedLabel } from '~/lib/utils/common_utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';

import IssuableAssignees from '~/vue_shared/components/issue/issue_assignees.vue';

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
    author() {
      return this.issuable.author;
    },
    authorId() {
      return getIdFromGraphQLId(`${this.author.id}`);
    },
    isIssuableUrlExternal() {
      // Check if URL is relative, which means it is internal.
      if (!/^https?:\/\//g.test(this.issuable.webUrl)) {
        return false;
      }
      // In case URL is absolute, it may or may not be internal,
      // hence use `gon.gitlab_url` which is current instance domain.
      return !this.issuable.webUrl.includes(gon.gitlab_url);
    },
    labels() {
      return this.issuable.labels?.nodes || this.issuable.labels || [];
    },
    assignees() {
      return this.issuable.assignees || [];
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
    showDiscussions() {
      return typeof this.issuable.userDiscussionsCount === 'number';
    },
    showIssuableMeta() {
      return Boolean(
        this.hasSlotContents('status') || this.showDiscussions || this.issuable.assignees,
      );
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
        const key = encodeURIComponent('label_name[]');
        const value = encodeURIComponent(this.labelTitle(label));
        return `?${key}=${value}`;
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
  <li class="issue gl-px-5!">
    <div class="issuable-info-container">
      <div v-if="showCheckbox" class="issue-check">
        <gl-form-checkbox
          class="gl-mr-0"
          :checked="checked"
          @input="$emit('checked-input', $event)"
        />
      </div>
      <div class="issuable-main-info">
        <div data-testid="issuable-title" class="issue-title title">
          <span class="issue-title-text" dir="auto">
            <gl-link :href="issuable.webUrl" v-bind="issuableTitleProps"
              >{{ issuable.title
              }}<gl-icon v-if="isIssuableUrlExternal" name="external-link" class="gl-ml-2"
            /></gl-link>
          </span>
        </div>
        <div class="issuable-info">
          <slot v-if="hasSlotContents('reference')" name="reference"></slot>
          <span v-else data-testid="issuable-reference" class="issuable-reference"
            >{{ issuableSymbol }}{{ issuable.iid }}</span
          >
          <span class="issuable-authored d-none d-sm-inline-block">
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
          <li
            v-if="showDiscussions"
            data-testid="issuable-discussions"
            class="issuable-comments gl-display-none gl-display-sm-block"
          >
            <gl-link
              v-gl-tooltip:tooltipcontainer.top
              :title="__('Comments')"
              :href="`${issuable.webUrl}#notes`"
              :class="{ 'no-comments': !issuable.userDiscussionsCount }"
              class="gl-reset-color!"
            >
              <gl-icon name="comments" />
              {{ issuable.userDiscussionsCount }}
            </gl-link>
          </li>
          <li v-if="assignees.length" class="gl-display-flex">
            <issuable-assignees
              :assignees="issuable.assignees"
              :icon-size="16"
              :max-visible="4"
              img-css-classes="gl-mr-2!"
              class="gl-align-items-center gl-display-flex gl-ml-3"
            />
          </li>
        </ul>
        <div
          data-testid="issuable-updated-at"
          class="float-right issuable-updated-at d-none d-sm-inline-block"
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
