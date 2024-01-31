<script>
import { GlTooltipDirective } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import CommitInfo from '~/repository/components/commit_info.vue';

export default {
  name: 'BlameInfo',
  components: {
    CommitInfo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    blameInfo: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <div class="blame gl-bg-gray-10 gl-border-r">
    <div class="blame-commit gl-border-none!">
      <commit-info
        v-for="(blame, index) in blameInfo"
        :key="index"
        :class="{ 'gl-border-t': blame.blameOffset !== '0px' }"
        class="gl-display-flex gl-absolute gl-px-3"
        :style="{ top: blame.blameOffset }"
        :commit="blame.commit"
        :span="blame.span"
        :prev-blame-link="blame.commitData && blame.commitData.projectBlameLink"
      />
    </div>
  </div>
</template>
