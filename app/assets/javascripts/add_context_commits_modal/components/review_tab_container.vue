<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import CommitItem from '~/diffs/components/commit_item.vue';
import { __ } from '~/locale';

export default {
  components: {
    GlLoadingIcon,
    GlAlert,
    CommitItem,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    loadingError: {
      type: Boolean,
      required: true,
    },
    loadingFailedText: {
      type: String,
      required: true,
    },
    commits: {
      type: Array,
      required: true,
    },
    emptyListText: {
      type: String,
      required: false,
      default: __('No commits present here'),
    },
  },
};
</script>
<template>
  <gl-loading-icon v-if="isLoading" size="lg" class="mt-3" />
  <gl-alert v-else-if="loadingError" variant="danger" :dismissible="false" class="mt-3">
    {{ loadingFailedText }}
  </gl-alert>
  <div v-else-if="commits.length === 0" class="text-center mt-4">
    <span>{{ emptyListText }}</span>
  </div>
  <div v-else>
    <ul class="content-list commit-list flex-list">
      <commit-item
        v-for="(commit, index) in commits"
        :key="commit.id"
        :is-selectable="true"
        :commit="commit"
        :checked="commit.isSelected"
        @handleCheckboxChange="$emit('handleCommitSelect', [index, $event])"
      />
    </ul>
  </div>
</template>
