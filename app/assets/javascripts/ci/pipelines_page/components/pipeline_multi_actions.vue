<script>
import {
  GlAlert,
  GlDisclosureDropdown,
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
  searchPlaceholder: __('Search artifacts'),
  downloadArtifacts: __('Download artifacts'),
  artifactsFetchErrorMessage: s__('Pipelines|Could not load artifacts.'),
  artifactsFetchWarningMessage: s__(
    'Pipelines|Failed to update. Please reload page to update the list of artifacts.',
  ),
  emptyArtifactsMessage: __('No artifacts found'),
};

export default {
  i18n,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAlert,
    GlDisclosureDropdown,
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
      isNewPipeline: false,
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
    items() {
      return this.filteredArtifacts.map(({ name, path }) => ({
        text: name,
        href: path,
        extraAttrs: {
          download: '',
          rel: 'nofollow',
          'data-testid': 'artifact-item',
        },
      }));
    },
  },
  watch: {
    pipelineId() {
      this.isNewPipeline = true;
    },
  },
  methods: {
    fetchArtifacts() {
      // refactor tracking based on action once this dropdown supports
      // actions other than artifacts
      this.track('click_artifacts_dropdown', { label: TRACKING_CATEGORIES.table });

      // Preserve the last good list and present it if a request fails
      const oldArtifacts = [...this.artifacts];
      this.artifacts = [];

      this.hasError = false;
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
          this.isNewPipeline = false;
        })
        .catch(() => {
          this.hasError = true;
          if (!this.isNewPipeline) {
            this.artifacts = oldArtifacts;
          }
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    onDisclosureDropdownShown() {
      this.fetchArtifacts();
    },
    onDisclosureDropdownHidden() {
      this.searchQuery = '';
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    v-gl-tooltip
    class="gl-text-left"
    :title="$options.i18n.downloadArtifacts"
    :toggle-text="$options.i18n.downloadArtifacts"
    :aria-label="$options.i18n.downloadArtifacts"
    :items="items"
    icon="download"
    placement="bottom-end"
    text-sr-only
    data-testid="pipeline-multi-actions-dropdown"
    @shown="onDisclosureDropdownShown"
    @hidden="onDisclosureDropdownHidden"
  >
    <template #header>
      <div
        class="gl-flex gl-min-h-8 gl-items-center gl-border-b-1 gl-border-b-dropdown !gl-p-4 gl-text-sm gl-font-bold gl-text-strong gl-border-b-solid"
      >
        {{ $options.i18n.downloadArtifacts }}
      </div>
      <div v-if="hasArtifacts" class="gl-border-b-1 gl-border-b-dropdown gl-border-b-solid">
        <gl-search-box-by-type
          ref="searchInput"
          v-model.trim="searchQuery"
          :placeholder="$options.i18n.searchPlaceholder"
          borderless
          autofocus
        />
      </div>
      <gl-alert
        v-if="hasError && !hasArtifacts"
        variant="danger"
        :dismissible="false"
        data-testid="artifacts-fetch-error"
      >
        {{ $options.i18n.artifactsFetchErrorMessage }}
      </gl-alert>
    </template>

    <gl-loading-icon v-if="isLoading" class="gl-m-3" size="sm" />
    <p
      v-else-if="filteredArtifacts.length === 0"
      class="gl-m-0 gl-px-4 gl-py-3 gl-text-subtle"
      data-testid="artifacts-empty-message"
    >
      {{ $options.i18n.emptyArtifactsMessage }}
    </p>

    <template #footer>
      <p
        v-if="hasError && hasArtifacts"
        class="gl-border-t gl-mb-0 gl-px-5 gl-py-4 gl-text-sm gl-text-subtle"
        data-testid="artifacts-fetch-warning"
      >
        {{ $options.i18n.artifactsFetchWarningMessage }}
      </p>
    </template>
  </gl-disclosure-dropdown>
</template>
