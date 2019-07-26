<script>
import { __, sprintf } from '~/locale';
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
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
      default: 'issue',
      required: false,
    },
  },
  computed: {
    cannotMerge() {
      return this.issuableType === 'merge_request' && !this.user.can_merge;
    },
    tooltipTitle() {
      if (this.cannotMerge && this.tooltipHasName) {
        return sprintf(__('%{userName} (cannot merge)'), { userName: this.user.name });
      } else if (this.cannotMerge) {
        return __('Cannot merge');
      } else if (this.tooltipHasName) {
        return this.user.name;
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
    assigneeUrl() {
      return joinPaths(`${this.rootPath}`, `${this.user.username}`);
    },
  },
};
</script>

<template>
  <gl-link v-gl-tooltip="tooltipOption" :href="assigneeUrl" :title="tooltipTitle" class="d-flex">
    <assignee-avatar :user="user" :img-size="32" :issuable-type="issuableType" />
    <slot :user="user"></slot>
  </gl-link>
</template>
