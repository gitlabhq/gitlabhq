<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    Icon,
    GlLink,
  },
  props: {
    artifacts: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <div class="btn-group" role="group">
    <button
      v-gl-tooltip
      type="button"
      class="dropdown-toggle build-artifacts btn btn-default js-pipeline-dropdown-download"
      :title="__('Artifacts')"
      data-toggle="dropdown"
      :aria-label="__('Artifacts')"
    >
      <icon name="download" />
      <i class="fa fa-caret-down" aria-hidden="true"></i>
    </button>
    <ul class="dropdown-menu dropdown-menu-right">
      <li v-for="(artifact, i) in artifacts" :key="i">
        <gl-link :href="artifact.path" rel="nofollow" download
          >Download {{ artifact.name }} artifacts</gl-link
        >
      </li>
    </ul>
  </div>
</template>
