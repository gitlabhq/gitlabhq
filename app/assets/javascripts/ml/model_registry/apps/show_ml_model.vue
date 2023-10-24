<script>
import { GlTab, GlTabs, GlBadge } from '@gitlab/ui';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import * as i18n from '../translations';

export default {
  name: 'ShowMlModelApp',
  components: {
    TitleArea,
    GlTabs,
    GlTab,
    GlBadge,
    MetadataItem,
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
        <h3 class="gl-font-lg">{{ $options.i18n.LATEST_VERSION_LABEL }}</h3>
        <template v-if="model.latestVersion">
          {{ model.latestVersion.version }}
        </template>
        <div v-else class="gl-text-secondary">{{ $options.i18n.NO_VERSIONS_LABEL }}</div>
      </gl-tab>
      <gl-tab>
        <template #title>
          {{ $options.i18n.MODEL_OTHER_VERSIONS_TAB_LABEL }}
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ versionCount }}</gl-badge>
        </template>
      </gl-tab>
      <gl-tab>
        <template #title>
          {{ $options.i18n.MODEL_CANDIDATES_TAB_LABEL }}
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ candidateCount }}</gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
