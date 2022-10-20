<script>
import {
  GlAlert,
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlLoadingIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import { TRACKING_CATEGORIES } from '../../constants';

export const i18n = {
  downloadArtifacts: __('Download artifacts'),
  artifactsFetchErrorMessage: s__('Pipelines|Could not load artifacts.'),
  emptyArtifactsMessage: __('No artifacts found'),
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
    GlSearchBoxByType,
    GlLoadingIcon,
  },
  mixins: [Tracking.mixin()],
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
      searchQuery: '',
    };
  },
  computed: {
    hasArtifacts() {
      return this.artifacts.length > 0;
    },
    filteredArtifacts() {
      return this.searchQuery.length > 0
        ? fuzzaldrinPlus.filter(this.artifacts, this.searchQuery, { key: 'name' })
        : this.artifacts;
    },
  },
  methods: {
    fetchArtifacts() {
      // refactor tracking based on action once this dropdown supports
      // actions other than artifacts
      this.track('click_artifacts_dropdown', { label: TRACKING_CATEGORIES.table });

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
    handleDropdownShown() {
      if (this.hasArtifacts) {
        this.$refs.searchInput.focusInput();
      }
    },
  },
};
</script>
<template>
  <gl-dropdown
    v-gl-tooltip
    :title="$options.i18n.downloadArtifacts"
    :text="$options.i18n.downloadArtifacts"
    :aria-label="$options.i18n.downloadArtifacts"
    :header-text="$options.i18n.downloadArtifacts"
    icon="download"
    data-testid="pipeline-multi-actions-dropdown"
    right
    lazy
    text-sr-only
    @show.once="fetchArtifacts"
    @shown="handleDropdownShown"
  >
    <gl-alert v-if="hasError" variant="danger" :dismissible="false">
      {{ $options.i18n.artifactsFetchErrorMessage }}
    </gl-alert>

    <gl-loading-icon v-else-if="isLoading" size="sm" />

    <gl-dropdown-item v-else-if="!hasArtifacts" data-testid="artifacts-empty-message">
      {{ $options.i18n.emptyArtifactsMessage }}
    </gl-dropdown-item>

    <template #header>
      <gl-search-box-by-type v-if="hasArtifacts" ref="searchInput" v-model.trim="searchQuery" />
    </template>

    <gl-dropdown-item
      v-for="(artifact, i) in filteredArtifacts"
      :key="i"
      :href="artifact.path"
      rel="nofollow"
      download
      class="gl-word-break-word"
      data-testid="artifact-item"
    >
      {{ artifact.name }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
