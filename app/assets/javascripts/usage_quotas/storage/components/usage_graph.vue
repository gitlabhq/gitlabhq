<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { PROJECT_STORAGE_TYPES } from '../constants';
import { descendingStorageUsageSort } from '../utils';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    rootStorageStatistics: {
      required: true,
      type: Object,
    },
    limit: {
      required: true,
      type: Number,
    },
  },
  computed: {
    storageTypes() {
      const {
        containerRegistrySize,
        buildArtifactsSize,
        pipelineArtifactsSize,
        lfsObjectsSize,
        packagesSize,
        repositorySize,
        storageSize,
        wikiSize,
        snippetsSize,
        uploadsSize,
      } = this.rootStorageStatistics;
      const artifactsSize = buildArtifactsSize + pipelineArtifactsSize;

      if (storageSize === 0) {
        return null;
      }

      return [
        {
          id: 'repositorySize',
          style: this.usageStyle(this.barRatio(repositorySize)),
          class: 'gl-bg-data-viz-blue-500',
          size: repositorySize,
        },
        {
          id: 'lfsObjectsSize',
          style: this.usageStyle(this.barRatio(lfsObjectsSize)),
          class: 'gl-bg-data-viz-orange-600',
          size: lfsObjectsSize,
        },
        {
          id: 'packagesSize',
          style: this.usageStyle(this.barRatio(packagesSize)),
          class: 'gl-bg-data-viz-aqua-500',
          size: packagesSize,
        },
        {
          id: 'containerRegistrySize',
          style: this.usageStyle(this.barRatio(containerRegistrySize)),
          class: 'gl-bg-data-viz-aqua-800',
          size: containerRegistrySize,
        },
        {
          id: 'buildArtifactsSize',
          style: this.usageStyle(this.barRatio(artifactsSize)),
          class: 'gl-bg-data-viz-green-600',
          size: artifactsSize,
        },
        {
          id: 'wikiSize',
          style: this.usageStyle(this.barRatio(wikiSize)),
          class: 'gl-bg-data-viz-magenta-500',
          size: wikiSize,
        },
        {
          id: 'snippetsSize',
          style: this.usageStyle(this.barRatio(snippetsSize)),
          class: 'gl-bg-data-viz-orange-800',
          size: snippetsSize,
        },
        {
          id: 'uploadsSize',
          style: this.usageStyle(this.barRatio(uploadsSize)),
          class: 'gl-bg-data-viz-aqua-700',
          size: uploadsSize,
        },
      ]
        .filter((data) => data.size !== 0)
        .sort(descendingStorageUsageSort('size'))
        .map((storageType) => {
          const storageTypeExtraData = PROJECT_STORAGE_TYPES.find(
            (type) => storageType.id === type.id,
          );
          const { name, tooltip } = storageTypeExtraData || {};

          return {
            name,
            tooltip,
            ...storageType,
          };
        });
    },
  },
  methods: {
    formatSize(size) {
      return numberToHumanSize(size);
    },
    usageStyle(ratio) {
      return { flex: ratio };
    },
    barRatio(size) {
      let max = this.rootStorageStatistics.storageSize;

      if (this.limit !== 0 && max <= this.limit) {
        max = this.limit;
      }

      return size / max;
    },
  },
};
</script>
<template>
  <div v-if="storageTypes" class="gl-display-flex gl-flex-direction-column w-100">
    <div class="gl-h-6 gl-my-5 gl-bg-gray-50 gl-rounded-base gl-display-flex">
      <div
        v-for="storageType in storageTypes"
        :key="storageType.name"
        class="storage-type-usage gl-h-full gl-display-inline-block"
        :class="storageType.class"
        :style="storageType.style"
        data-testid="storage-type-usage"
      ></div>
    </div>
    <div class="row gl-mb-4">
      <div
        v-for="storageType in storageTypes"
        :key="storageType.name"
        class="col-md-auto gl-display-flex gl-align-items-center"
        data-testid="storage-type-legend"
        data-qa-selector="storage_type_legend"
      >
        <div class="gl-h-2 gl-w-5 gl-mr-2 gl-display-inline-block" :class="storageType.class"></div>
        <span class="gl-mr-2 gl-font-weight-bold gl-font-sm">
          {{ storageType.name }}
        </span>
        <span class="gl-text-gray-500 gl-font-sm">
          {{ formatSize(storageType.size) }}
        </span>
        <span
          v-if="storageType.tooltip"
          v-gl-tooltip
          :title="storageType.tooltip"
          :aria-label="storageType.tooltip"
          class="gl-ml-2"
        >
          <gl-icon name="question" :size="12" />
        </span>
      </div>
    </div>
  </div>
</template>
