<script>
import { GlButton } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import { DEFAULT_PAGE_SIZE } from '../../constants';

export default {
  name: 'GlqlPagination',
  components: {
    GlButton,
  },
  props: {
    count: {
      type: Number,
      required: false,
      default: 0,
    },
    totalCount: {
      type: Number,
      required: false,
      default: 0,
    },
    loading: {
      type: [Boolean, Number],
      required: false,
      default: false,
    },
  },
  data() {
    return {
      pageSize: DEFAULT_PAGE_SIZE,
    };
  },
  computed: {
    hasNextPage() {
      return this.count < this.totalCount;
    },
    loadMoreLabel() {
      if (this.loading) {
        return sprintf(__('Loading %{count} more...'), { count: this.actualPageSize });
      }

      return sprintf(__('Load %{count} more'), { count: this.actualPageSize });
    },
    actualPageSize() {
      return Math.min(this.pageSize, this.totalCount - this.count);
    },
  },
};
</script>
<template>
  <div class="gl-flex gl-items-center gl-justify-center" data-testid="footer">
    <gl-button
      v-if="hasNextPage"
      data-testid="load-more-button"
      category="primary"
      size="small"
      variant="default"
      :aria-label="loadMoreLabel"
      :loading="Boolean(loading)"
      @click="$emit('loadMore', actualPageSize)"
    >
      {{ loadMoreLabel }}
    </gl-button>
  </div>
</template>
