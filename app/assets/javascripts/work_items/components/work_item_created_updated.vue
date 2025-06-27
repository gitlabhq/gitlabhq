<script>
import { GlAvatarLink, GlSprintf, GlLoadingIcon } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import { WORKSPACE_PROJECT } from '~/issues/constants';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import { findNotesWidget } from '../utils';
import WorkItemStateBadge from './work_item_state_badge.vue';
import WorkItemTypeIcon from './work_item_type_icon.vue';

export default {
  components: {
    HiddenBadge,
    ImportedBadge,
    LockedBadge,
    GlAvatarLink,
    GlSprintf,
    TimeAgoTooltip,
    WorkItemStateBadge,
    WorkItemTypeIcon,
    ConfidentialityBadge,
    GlLoadingIcon,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      workItem: {},
    };
  },
  computed: {
    createdAt() {
      return this.workItem?.createdAt || '';
    },
    author() {
      return this.workItem?.author ?? {};
    },
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
    workItemState() {
      return this.workItem?.state;
    },
    workItemType() {
      return this.workItem?.workItemType?.name;
    },
    workItemMovedToWorkItemUrl() {
      return this.workItem?.movedToWorkItemUrl;
    },
    workItemDuplicatedToWorkItemUrl() {
      return this.workItem?.duplicatedToWorkItemUrl;
    },
    workItemPromotedToEpicUrl() {
      return this.workItem?.promotedToEpicUrl;
    },
    isDiscussionLocked() {
      return findNotesWidget(this.workItem)?.discussionLocked;
    },
    isWorkItemConfidential() {
      return this.workItem?.confidential;
    },
    isLoading() {
      return this.$apollo.queries.workItem.loading;
    },
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      skip() {
        return !this.workItemIid;
      },
      update(data) {
        return data.workspace.workItem ?? {};
      },
    },
  },
  WORKSPACE_PROJECT,
};
</script>

<template>
  <div v-if="isLoading">
    <gl-loading-icon inline />
  </div>
  <div v-else class="gl-my-2 gl-text-subtle">
    <work-item-state-badge
      v-if="workItemState"
      :work-item-state="workItemState"
      :duplicated-to-work-item-url="workItemDuplicatedToWorkItemUrl"
      :moved-to-work-item-url="workItemMovedToWorkItemUrl"
      :promoted-to-epic-url="workItemPromotedToEpicUrl"
    />
    <confidentiality-badge
      v-if="isWorkItemConfidential"
      class="gl-align-middle"
      :issuable-type="workItemType"
      :workspace-type="$options.WORKSPACE_PROJECT"
      hide-text-in-small-screens
    />
    <locked-badge v-if="isDiscussionLocked" class="gl-align-middle" :issuable-type="workItemType" />
    <hidden-badge v-if="workItem.hidden" class="gl-align-middle" />
    <imported-badge v-if="workItem.imported" class="gl-align-middle" />
    <work-item-type-icon
      v-if="workItemType"
      class="gl-align-middle"
      :work-item-type="workItemType"
      show-text
      icon-class="gl-fill-icon-subtle"
    />
    <span data-testid="work-item-created" class="gl-align-middle">
      <gl-sprintf v-if="author.name" :message="__('created %{timeAgo} by %{author}')">
        <template #timeAgo>
          <time-ago-tooltip :time="createdAt" />
        </template>
        <template #author>
          <gl-avatar-link
            class="js-user-link gl-font-bold gl-text-default"
            :title="author.name"
            :data-user-id="authorId"
            :href="author.webUrl"
            data-testid="work-item-author"
          >
            {{ author.name }}
          </gl-avatar-link>
        </template>
      </gl-sprintf>
      <gl-sprintf v-else-if="createdAt" :message="__('created %{timeAgo}')">
        <template #timeAgo>
          <time-ago-tooltip :time="createdAt" />
        </template>
      </gl-sprintf>
    </span>
  </div>
</template>
