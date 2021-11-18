<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';

export const i18n = {
  artifacts: __('Artifacts'),
  artifactSectionHeader: __('Download artifacts'),
};

export default {
  i18n,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
  },
  inject: {
    artifactsEndpoint: {
      default: '',
    },
    artifactsEndpointPlaceholder: {
      default: '',
    },
  },
  props: {
    pipelineId: {
      type: Number,
      required: true,
    },
    artifacts: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    shouldShowDropdown() {
      return this.artifacts?.length;
    },
  },
};
</script>
<template>
  <gl-dropdown
    v-if="shouldShowDropdown"
    v-gl-tooltip
    class="build-artifacts js-pipeline-dropdown-download"
    :title="$options.i18n.artifacts"
    :text="$options.i18n.artifacts"
    :aria-label="$options.i18n.artifacts"
    icon="download"
    right
    lazy
    text-sr-only
  >
    <gl-dropdown-section-header>{{
      $options.i18n.artifactSectionHeader
    }}</gl-dropdown-section-header>

    <gl-dropdown-item
      v-for="(artifact, i) in artifacts"
      :key="i"
      :href="artifact.path"
      rel="nofollow"
      download
      class="gl-word-break-word"
    >
      {{ artifact.name }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
