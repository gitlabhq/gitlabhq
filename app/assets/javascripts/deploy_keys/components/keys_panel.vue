<script>
import deployKey from './key.vue';

export default {
  components: {
    deployKey,
  },
  props: {
    keys: {
      type: Array,
      required: true,
    },
    store: {
      type: Object,
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <div class="deploy-keys-panel table-holder">
    <template v-if="keys.length > 0">
      <div role="row" class="gl-responsive-table-row table-row-header">
        <div role="rowheader" class="table-section section-40">
          {{ s__('DeployKeys|Deploy key') }}
        </div>
        <div role="rowheader" class="table-section section-30">
          {{ s__('DeployKeys|Project usage') }}
        </div>
        <div role="rowheader" class="table-section section-15 text-right">{{ __('Created') }}</div>
      </div>
      <deploy-key
        v-for="deployKey in keys"
        :key="deployKey.id"
        :deploy-key="deployKey"
        :store="store"
        :endpoint="endpoint"
        :project-id="projectId"
      />
    </template>
    <div v-else class="settings-message text-center gl-mt-5">
      {{ s__('DeployKeys|No deploy keys found. Create one with the form above.') }}
    </div>
  </div>
</template>
