<script>
import { GlAvatarLink, GlSprintf, GlLoadingIcon } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { WORKSPACE_PROJECT } from '~/issues/constants';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import WorkItemStateBadge from '~/work_items/components/work_item_state_badge.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';

export default {
  components: {
    GlAvatarLink,
    GlSprintf,
    TimeAgoTooltip,
    WorkItemStateBadge,
    WorkItemTypeIcon,
    ConfidentialityBadge,
    GlLoadingIcon,
  },
  inject: ['fullPath'],
  props: {
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    updateInProgress: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    createdAt() {
      return this.workItem?.createdAt || '';
    },
    updatedAt() {
      return this.workItem?.updatedAt || '';
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
    workItemIconName() {
      return this.workItem?.workItemType?.iconName;
    },
    isWorkItemConfidential() {
      return this.workItem?.confidential;
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
        return data.workspace.workItems.nodes[0] ?? {};
      },
    },
  },
  WORKSPACE_PROJECT,
};
</script>

<template>
  <div class="gl-mb-3 gl-text-gray-700">
    <work-item-state-badge v-if="workItemState" :work-item-state="workItemState" />
    <gl-loading-icon v-if="updateInProgress" :inline="true" class="gl-mr-3" />
    <confidentiality-badge
      v-if="isWorkItemConfidential"
      class="gl-vertical-align-middle gl-display-inline-flex! gl-mr-2"
      :issuable-type="workItemType"
      :workspace-type="$options.WORKSPACE_PROJECT"
    />
    <work-item-type-icon
      class="gl-vertical-align-middle gl-mr-0!"
      :work-item-icon-name="workItemIconName"
      :work-item-type="workItemType"
      show-text
    />
    <span data-testid="work-item-created" class="gl-vertical-align-middle">
      <gl-sprintf v-if="author.name" :message="__('created %{timeAgo} by %{author}')">
        <template #timeAgo>
          <time-ago-tooltip :time="createdAt" />
        </template>
        <template #author>
          <gl-avatar-link
            class="js-user-link gl-text-body gl-font-weight-bold"
            :title="author.name"
            :data-user-id="authorId"
            :href="author.webUrl"
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

    <span
      v-if="updatedAt"
      class="gl-ml-5 gl-display-none gl-sm-display-inline-block gl-vertical-align-middle"
      data-testid="work-item-updated"
    >
      <gl-sprintf :message="__('Updated %{timeAgo}')">
        <template #timeAgo>
          <time-ago-tooltip :time="updatedAt" />
        </template>
      </gl-sprintf>
    </span>
  </div>
</template>
