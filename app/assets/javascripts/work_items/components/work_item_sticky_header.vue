<script>
import { GlLink } from '@gitlab/ui';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import ArchivedBadge from '~/issuable/components/archived_badge.vue';
import { NAMESPACE_PROJECT } from '~/issues/constants';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { titleInLinkSafeHtmlConfig } from '~/lib/dompurify';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import { STATE_CLOSED } from '~/work_items/constants';
import { findNotesWidget } from '../utils';
import WorkItemStateBadge from './work_item_state_badge.vue';

export default {
  name: 'WorkItemStickyHeader',
  components: {
    HiddenBadge,
    ImportedBadge,
    LockedBadge,
    ArchivedBadge,
    ConfidentialityBadge,
    WorkItemStateBadge,
    GlLink,
    WorkItemTypeIcon,
  },
  directives: {
    SafeHtml,
  },
  props: {
    workItem: {
      type: Object,
      required: true,
    },
    isDrawer: {
      type: Boolean,
      required: false,
      default: false,
    },
    archived: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isDiscussionLocked() {
      return findNotesWidget(this.workItem)?.discussionLocked;
    },
    workItemType() {
      return this.workItem.workItemType?.name;
    },
    workItemTypeIconName() {
      return this.workItem.workItemType?.iconName;
    },
    workItemState() {
      return this.workItem.state;
    },
  },
  NAMESPACE_PROJECT,
  STATE_CLOSED,
  TITLE_CLASS: 'gl-mr-auto gl-block gl-truncate gl-pr-3 gl-font-bold gl-text-strong',
  titleInLinkSafeHtmlConfig,
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-gap-3">
    <archived-badge v-if="archived" :issuable-type="workItemType" />
    <work-item-state-badge
      v-else-if="workItemState === $options.STATE_CLOSED"
      :work-item-state="workItemState"
      :promoted-to-epic-url="workItem.promotedToEpicUrl"
      :duplicated-to-work-item-url="workItem.duplicatedToWorkItemUrl"
      :moved-to-work-item-url="workItem.movedToWorkItemUrl"
    />
    <confidentiality-badge
      v-if="workItem.confidential"
      :issuable-type="workItemType"
      :workspace-type="$options.NAMESPACE_PROJECT"
      hide-text-in-small-screens
    />
    <locked-badge v-if="isDiscussionLocked" :issuable-type="workItemType" />
    <hidden-badge v-if="workItem.hidden" />
    <imported-badge v-if="workItem.imported" />
    <work-item-type-icon
      v-if="workItemType"
      class="gl-align-middle"
      :work-item-type="workItemType"
      :type-icon-name="workItemTypeIconName"
      show-tooltip-on-hover
      icon-class="gl-fill-icon-subtle"
    />
    <span v-if="isDrawer" v-safe-html="workItem.titleHtml" :class="$options.TITLE_CLASS"></span>
    <gl-link v-else :class="$options.TITLE_CLASS" href="#top" :title="workItem.title">
      <span v-safe-html:[$options.titleInLinkSafeHtmlConfig]="workItem.titleHtml"></span>
    </gl-link>
  </div>
</template>
