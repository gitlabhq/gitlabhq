<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import { GlLink, GlTooltipDirective, GlIcon } from '@gitlab/ui';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
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
      <gl-icon name="download" />
      <gl-icon name="chevron-down" />
    </button>
    <ul class="dropdown-menu dropdown-menu-right">
      <li v-for="(artifact, i) in artifacts" :key="i">
        <gl-link :href="artifact.path" rel="nofollow" download
          >Download {{ artifact.name }} artifact</gl-link
        >
      </li>
    </ul>
  </div>
</template>
