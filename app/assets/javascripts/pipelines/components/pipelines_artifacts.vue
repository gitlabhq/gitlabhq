<script>
import { GlLink, GlButton, GlTooltipDirective } from '@gitlab-org/gitlab-ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    Icon,
    GlLink,
    GlButton,
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
  <div
    class="btn-group"
    role="group"
  >
    <gl-button
      v-gl-tooltip
      class="dropdown-toggle build-artifacts js-pipeline-dropdown-download"
      title="Artifacts"
      data-toggle="dropdown"
      aria-label="Artifacts"
    >
      <icon name="download" />
      <i
        class="fa fa-caret-down"
        aria-hidden="true"
      >
      </i>
    </gl-button>
    <ul class="dropdown-menu dropdown-menu-right">
      <li
        v-for="(artifact, i) in artifacts"
        :key="i"
      >
        <gl-link
          :href="artifact.path"
          rel="nofollow"
          download
        >
          Download {{ artifact.name }} artifacts
        </gl-link>
      </li>
    </ul>
  </div>
</template>
