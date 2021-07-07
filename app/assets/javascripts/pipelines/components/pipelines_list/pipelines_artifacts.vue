<script>
import {
  GlAlert,
  GlDropdown,
  GlDropdownItem,
  GlLoadingIcon,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';

export const i18n = {
  artifacts: __('Artifacts'),
  downloadArtifact: __('Download %{name} artifact'),
  artifactSectionHeader: __('Download artifacts'),
  artifactsFetchErrorMessage: s__('Pipelines|Could not load artifacts.'),
  noArtifacts: s__('Pipelines|No artifacts available'),
};

export default {
  i18n,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAlert,
    GlDropdown,
    GlDropdownItem,
    GlLoadingIcon,
    GlSprintf,
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
  },
  data() {
    return {
      artifacts: [],
      hasError: false,
      isLoading: false,
    };
  },
  computed: {
    hasArtifacts() {
      return Boolean(this.artifacts.length);
    },
  },
  methods: {
    fetchArtifacts() {
      this.isLoading = true;
      // Replace the placeholder with the ID of the pipeline we are viewing
      const endpoint = this.artifactsEndpoint.replace(
        this.artifactsEndpointPlaceholder,
        this.pipelineId,
      );
      return axios
        .get(endpoint)
        .then(({ data }) => {
          this.artifacts = data.artifacts;
        })
        .catch(() => {
          this.hasError = true;
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>
<template>
  <gl-dropdown
    v-gl-tooltip
    class="build-artifacts js-pipeline-dropdown-download"
    :title="$options.i18n.artifacts"
    :text="$options.i18n.artifacts"
    :aria-label="$options.i18n.artifacts"
    icon="download"
    right
    lazy
    text-sr-only
    @show.once="fetchArtifacts"
  >
    <gl-alert v-if="hasError" variant="danger" :dismissible="false">
      {{ $options.i18n.artifactsFetchErrorMessage }}
    </gl-alert>

    <gl-loading-icon v-if="isLoading" size="sm" />

    <gl-alert v-else-if="!hasArtifacts" variant="info" :dismissible="false">
      {{ $options.i18n.noArtifacts }}
    </gl-alert>

    <gl-dropdown-item
      v-for="(artifact, i) in artifacts"
      :key="i"
      :href="artifact.path"
      rel="nofollow"
      download
    >
      <gl-sprintf :message="$options.i18n.downloadArtifact">
        <template #name>{{ artifact.name }}</template>
      </gl-sprintf>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
