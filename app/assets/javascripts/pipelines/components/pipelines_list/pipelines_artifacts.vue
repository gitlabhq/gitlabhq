<script>
import { GlDropdown, GlDropdownItem, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSprintf,
  },
  translations: {
    artifacts: __('Artifacts'),
    downloadArtifact: __('Download %{name} artifact'),
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
    class="build-artifacts js-pipeline-dropdown-download"
    :title="$options.translations.artifacts"
    :text="$options.translations.artifacts"
    :aria-label="$options.translations.artifacts"
    icon="download"
    text-sr-only
  >
    <gl-dropdown-item
      v-for="(artifact, i) in artifacts"
      :key="i"
      :href="artifact.path"
      rel="nofollow"
      download
    >
      <gl-sprintf :message="$options.translations.downloadArtifact">
        <template #name>{{ artifact.name }}</template>
      </gl-sprintf>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
