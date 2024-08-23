<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { isGid, getIdFromGraphQLId } from '~/graphql_shared/utils';
import AssigneeAvatar from './assignee_avatar.vue';

export default {
  components: {
    AssigneeAvatar,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    issuableType: {
      type: String,
      default: TYPE_ISSUE,
      required: false,
    },
  },
  computed: {
    isMergeRequest() {
      return this.issuableType === TYPE_MERGE_REQUEST;
    },
    cannotMerge() {
      const canMerge = this.user.mergeRequestInteraction?.canMerge || this.user.can_merge;
      return this.isMergeRequest && !canMerge;
    },
    assigneeUrl() {
      return this.user.web_url || this.user.webUrl;
    },
    assigneeId() {
      return isGid(this.user.id) ? getIdFromGraphQLId(this.user.id) : this.user.id;
    },
  },
};
</script>

<template>
  <!-- must be `gl-inline-block` or parent flex-basis causes width issues -->
  <gl-link
    :href="assigneeUrl"
    :data-user-id="assigneeId"
    :data-username="user.username"
    :data-cannot-merge="cannotMerge"
    data-placement="left"
    class="js-user-link gl-inline-block"
  >
    <!-- use gl-flex so that slot can be appropriately styled -->
    <span class="gl-flex">
      <assignee-avatar :user="user" :img-size="24" :issuable-type="issuableType" />
      <slot></slot>
    </span>
  </gl-link>
</template>
