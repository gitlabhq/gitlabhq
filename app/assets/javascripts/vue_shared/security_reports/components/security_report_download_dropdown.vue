<script>
import { GlDropdown, GlDropdownItem, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  name: 'SecurityReportDownloadDropdown',
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  directives: {
    GlTooltip,
  },
  props: {
    artifacts: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    artifactText({ name }) {
      return sprintf(s__('SecurityReports|Download %{artifactName}'), {
        artifactName: name,
      });
    },
  },
};
</script>

<template>
  <gl-dropdown
    v-gl-tooltip
    :title="s__('SecurityReports|Download results')"
    :loading="loading"
    icon="download"
    size="small"
    right
  >
    <gl-dropdown-item
      v-for="artifact in artifacts"
      :key="artifact.path"
      :href="artifact.path"
      download
    >
      {{ artifactText(artifact) }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
