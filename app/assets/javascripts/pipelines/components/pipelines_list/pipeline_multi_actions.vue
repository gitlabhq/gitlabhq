<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    artifacts: __('Artifacts'),
    downloadArtifact: __('Download %{name} artifact'),
    artifactSectionHeader: __('Download artifacts'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlSprintf,
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
  <gl-dropdown
    v-gl-tooltip
    :title="$options.i18n.artifacts"
    :text="$options.i18n.artifacts"
    :aria-label="$options.i18n.artifacts"
    icon="ellipsis_v"
    data-testid="pipeline-multi-actions-dropdown"
    right
    lazy
    text-sr-only
    no-caret
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
      data-testid="artifact-item"
    >
      <gl-sprintf :message="$options.i18n.downloadArtifact">
        <template #name>{{ artifact.name }}</template>
      </gl-sprintf>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
