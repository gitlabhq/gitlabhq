<script>
import { GlTab, GlTabs, GlBadge } from '@gitlab/ui';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import * as i18n from '../translations';

export default {
  name: 'ShowMlModelApp',
  components: {
    ModelVersionList: () => import('../components/model_version_list.vue'),
    CandidateList: () => import('../components/candidate_list.vue'),
    TitleArea,
    GlTabs,
    GlTab,
    GlBadge,
    MetadataItem,
    ModelVersionDetail,
  },
  props: {
    model: {
      type: Object,
      required: true,
    },
  },
  computed: {
    versionCount() {
      return this.model.versionCount || 0;
    },
    candidateCount() {
      return this.model.candidateCount || 0;
    },
    latestVersionTitle() {
      return `${i18n.LATEST_VERSION_LABEL}: ${this.model.latestVersion.version}`;
    },
  },
  i18n,
};
</script>

<template>
  <div>
    <title-area :title="model.name">
      <template #metadata-versions-count>
        <metadata-item
          icon="machine-learning"
          :text="$options.i18n.versionsCountLabel(model.versionCount)"
        />
      </template>

      <template #sub-header>
        {{ model.description }}
      </template>
    </title-area>

    <gl-tabs class="gl-mt-4">
      <gl-tab :title="$options.i18n.MODEL_DETAILS_TAB_LABEL">
        <template v-if="model.latestVersion">
          <h3 class="gl-font-lg">{{ latestVersionTitle }}</h3>
          <model-version-detail :model-version="model.latestVersion" />
        </template>
        <div v-else class="gl-text-secondary">{{ $options.i18n.NO_VERSIONS_LABEL }}</div>
      </gl-tab>
      <gl-tab>
        <template #title>
          {{ $options.i18n.MODEL_OTHER_VERSIONS_TAB_LABEL }}
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ versionCount }}</gl-badge>
        </template>

        <model-version-list :model-id="model.id" />
      </gl-tab>
      <gl-tab>
        <template #title>
          {{ $options.i18n.MODEL_CANDIDATES_TAB_LABEL }}
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ candidateCount }}</gl-badge>
        </template>

        <candidate-list :model-id="model.id" />
      </gl-tab>
    </gl-tabs>
  </div>
</template>
