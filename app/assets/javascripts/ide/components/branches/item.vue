<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import { GlIcon } from '@gitlab/ui';
import Timeago from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlIcon,
    Timeago,
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
  <a :href="branchHref" class="btn-link d-flex align-items-center">
    <span class="d-flex gl-mr-3 ide-search-list-current-icon">
      <gl-icon v-if="isActive" :size="16" name="mobile-issue-close" />
    </span>
    <span>
      <strong> {{ item.name }} </strong>
      <span class="ide-merge-request-project-path d-block mt-1">
        Updated <timeago :time="item.committedDate || ''" />
      </span>
    </span>
  </a>
</template>
