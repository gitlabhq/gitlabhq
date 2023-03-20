<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { __, sprintf } from '~/locale';
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
    tooltipPlacement: {
      type: String,
      default: 'bottom',
      required: false,
    },
    tooltipHasName: {
      type: Boolean,
      default: true,
      required: false,
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
    tooltipTitle() {
      if (this.cannotMerge && this.tooltipHasName) {
        return sprintf(__('%{userName} (cannot merge)'), { userName: this.user.name });
      } else if (this.cannotMerge) {
        return __('Cannot merge');
      }

      return '';
    },
    tooltipOption() {
      return {
        container: 'body',
        placement: this.tooltipPlacement,
        boundary: 'viewport',
      };
    },
    reviewerUrl() {
      return this.user.webUrl;
    },
  },
};
</script>

<template>
  <!-- must be `d-inline-block` or parent flex-basis causes width issues -->
  <gl-link
    v-gl-tooltip="tooltipOption"
    :href="reviewerUrl"
    :title="tooltipTitle"
    class="gl-display-inline-block js-user-link"
  >
    <!-- use d-flex so that slot can be appropriately styled -->
    <span class="gl-display-flex">
      <reviewer-avatar :user="user" :img-size="24" :issuable-type="issuableType" />
      <slot :user="user"></slot>
    </span>
  </gl-link>
</template>
