<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import RunnerTag from './runner_tag.vue';

const BUFFER = 1; // A "+1 more" link is not useful, start from 2.
const TAG_LIST_MAX_LENGTH = 50; // Defined at app/models/ci/runner.rb

export default {
  components: {
    RunnerTag,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    tagList: {
      type: Array,
      required: false,
      default: () => [],
    },
    limit: {
      type: Number,
      required: false,
      default: TAG_LIST_MAX_LENGTH,
    },
  },
  data() {
    return {
      collapsed: true,
    };
  },
  computed: {
    tags() {
      // tagList can be null, handle that case by returning an empty array.
      return this.tagList || [];
    },
    limitedTags() {
      if (this.tags.length > this.limit + BUFFER) {
        return this.tags.slice(0, this.limit);
      }
      return this.tags;
    },
    shownTags() {
      if (this.collapsed) {
        return this.limitedTags;
      }
      return this.tags;
    },
    showMoreButton() {
      const count = this.tags.length - this.limitedTags.length;

      if (this.collapsed && count) {
        return {
          tooltip: sprintf(s__('Runners|Show %{count} more tags'), { count }),
          text: sprintf(s__('Runners|+%{count} more'), { count }),
        };
      }
      return null;
    },
  },
  methods: {
    onClick() {
      this.collapsed = false;
    },
  },
};
</script>
<template>
  <span v-if="shownTags.length">
    <runner-tag v-for="tag in shownTags" :key="tag" class="gl-mr-1" :tag="tag" />
    <button
      v-if="showMoreButton"
      v-gl-tooltip="showMoreButton.tooltip"
      class="gl-border-0 gl-bg-transparent gl-p-0 gl-text-sm gl-text-subtle"
      @click="onClick"
    >
      {{ showMoreButton.text }}
    </button>
  </span>
</template>
