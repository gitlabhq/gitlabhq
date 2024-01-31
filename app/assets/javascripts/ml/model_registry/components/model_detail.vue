<script>
import { GlLink } from '@gitlab/ui';
import EmptyState from '~/ml/model_registry/components/empty_state.vue';
import { MODEL_ENTITIES } from '~/ml/model_registry/constants';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';

export default {
  name: 'ModelDetail',
  components: {
    EmptyState,
    ModelVersionDetail,
    GlLink,
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
  },
  modelVersionEntity: MODEL_ENTITIES.modelVersion,
};
</script>

<template>
  <div v-if="model.latestVersion">
    <h3 class="gl-font-lg">
      {{ s__('MlModelRegistry|Latest version') }}:

      <gl-link :href="model.latestVersion.path" data-testid="model-version-link">
        {{ model.latestVersion.version }}
      </gl-link>
    </h3>

    <model-version-detail :model-version="model.latestVersion" />
  </div>

  <empty-state v-else :entity-type="$options.modelVersionEntity" />
</template>
