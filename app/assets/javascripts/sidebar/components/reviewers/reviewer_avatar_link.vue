<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import ReviewerAvatar from './reviewer_avatar.vue';

export default {
  components: {
    ReviewerAvatar,
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
    rootPath: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      default: TYPE_ISSUE,
      required: false,
    },
  },
  computed: {
    cannotMerge() {
      return (
        this.issuableType === TYPE_MERGE_REQUEST && !this.user.mergeRequestInteraction?.canMerge
      );
    },
    reviewerId() {
      return getIdFromGraphQLId(this.user.id);
    },
    reviewerUrl() {
      return this.user.webUrl;
    },
  },
};
</script>

<template>
  <!-- must be `gl-inline-block` or parent flex-basis causes width issues -->
  <gl-link
    :href="reviewerUrl"
    :data-user-id="reviewerId"
    :data-username="user.username"
    :data-cannot-merge="cannotMerge"
    data-placement="left"
    class="js-user-link gl-inline-block !gl-text-inherit hover:!gl-text-blue-800"
  >
    <!-- use gl-flex so that slot can be appropriately styled -->
    <span class="gl-flex">
      <reviewer-avatar :user="user" :img-size="24" :issuable-type="issuableType" />
      <slot :user="user"></slot>
    </span>
  </gl-link>
</template>
