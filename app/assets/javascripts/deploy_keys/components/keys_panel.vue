<script>
import DeployKey from './key.vue';

export default {
  components: {
    DeployKey,
  },
  props: {
    keys: {
      type: Array,
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
  <div class="deploy-keys-panel table-holder gl-bg-white gl-rounded-lg">
    <template v-if="keys.length > 0">
      <div
        role="row"
        class="gl-responsive-table-row table-row-header gl-font-base gl-font-bold gl-text-gray-900 gl-md-pl-5 gl-md-pr-5 gl-bg-gray-10 gl-border-gray-100!"
      >
        <div role="rowheader" class="table-section section-40">
          {{ s__('DeployKeys|Deploy key') }}
        </div>
        <div role="rowheader" class="table-section section-20">
          {{ s__('DeployKeys|Project usage') }}
        </div>
        <div role="rowheader" class="table-section section-15">{{ __('Created') }}</div>
        <div role="rowheader" class="table-section section-15">{{ __('Expires') }}</div>
        <!-- leave 10% space for actions --->
      </div>
      <deploy-key
        v-for="deployKey in keys"
        :key="deployKey.id"
        :deploy-key="deployKey"
        :project-id="projectId"
      />
    </template>
    <div v-else class="gl-new-card-empty gl-bg-gray-10 gl-text-center gl-p-5">
      {{ s__('DeployKeys|No deploy keys found, start by adding a new one above.') }}
    </div>
  </div>
</template>
