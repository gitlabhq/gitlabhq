<!-- eslint-disable vue/multi-word-component-names -->
<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import { GlIcon, GlButton } from '@gitlab/ui';
import Timeago from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlIcon,
    Timeago,
    GlButton,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    isActive: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    branchHref() {
      return this.$router.resolve(`/project/${this.projectId}/edit/${this.item.name}`).href;
    },
  },
};
</script>

<template>
  <gl-button variant="link" :href="branchHref">
    <span class="gl-flex gl-items-center">
      <span class="ide-search-list-current-icon gl-mr-3 gl-flex">
        <gl-icon v-if="isActive" :size="16" name="mobile-issue-close" />
      </span>
      <span class="gl-flex gl-flex-col gl-items-end">
        <strong> {{ item.name }} </strong>
        <span class="ide-merge-request-project-path mt-1 gl-block">
          Updated <timeago :time="item.committedDate || ''" />
        </span>
      </span>
    </span>
  </gl-button>
</template>
