<script>
import { GlButton } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import { eventHubByKey } from '../../utils/event_hub_factory';
import { DEFAULT_PAGE_SIZE } from '../../constants';

export default {
  name: 'GlqlFooter',
  components: {
    GlButton,
  },
  inject: ['queryKey'],
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
  },
  data() {
    return {
      eventHub: eventHubByKey(this.queryKey),
      isLoadingMore: false,

      pageSize: DEFAULT_PAGE_SIZE,
    };
  },
  computed: {
    hasNextPage() {
      return this.count < this.totalCount;
    },
    loadMoreLabel() {
      if (this.isLoadingMore) {
        return sprintf(__('Loading %{count} more...'), { count: this.actualPageSize });
      }

      return sprintf(__('Load %{count} more'), { count: this.actualPageSize });
    },
    actualPageSize() {
      return Math.min(this.pageSize, this.totalCount - this.count);
    },
  },

  mounted() {
    this.eventHub.$on('loadMore', () => {
      this.isLoadingMore = true;
    });

    this.eventHub.$on('loadMoreComplete', () => {
      this.isLoadingMore = false;
    });

    this.eventHub.$on('loadMoreError', () => {
      this.isLoadingMore = false;
    });
  },
  methods: {
    loadMore() {
      this.eventHub.$emit('loadMore', this.actualPageSize);
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
      :loading="isLoadingMore"
      @click="loadMore"
    >
      {{ loadMoreLabel }}
    </gl-button>
  </div>
</template>
