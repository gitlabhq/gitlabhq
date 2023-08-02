<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlKeysetPagination, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import ListItem from './list_item.vue';

export default {
  components: {
    GlLoadingIcon,
    GlKeysetPagination,
    GlSprintf,
    ListItem,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    savedReplies: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    count: {
      type: Number,
      required: true,
    },
  },
  methods: {
    prevPage() {
      this.$emit('input', {
        before: this.pageInfo.beforeCursor,
      });
    },
    nextPage() {
      this.$emit('input', {
        after: this.pageInfo.endCursor,
      });
    },
  },
};
</script>

<template>
  <div class="settings-section">
    <gl-loading-icon v-if="loading" size="lg" />
    <template v-else>
      <div class="settings-sticky-header">
        <div class="settings-sticky-header-inner">
          <h4 class="gl-my-0" data-testid="title">
            <gl-sprintf :message="__('My comment templates (%{count})')">
              <template #count>{{ count }}</template>
            </gl-sprintf>
          </h4>
        </div>
      </div>
      <ul class="gl-list-style-none gl-p-0 gl-m-0">
        <list-item v-for="template in savedReplies" :key="template.id" :template="template" />
      </ul>
      <gl-keyset-pagination
        v-if="pageInfo.hasPreviousPage || pageInfo.hasNextPage"
        v-bind="pageInfo"
        class="gl-mt-4"
        @prev="prevPage"
        @next="nextPage"
      />
    </template>
  </div>
</template>
