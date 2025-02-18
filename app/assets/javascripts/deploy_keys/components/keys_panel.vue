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
    hasSearch: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="deploy-keys-panel table-holder gl-rounded-lg gl-bg-white">
    <template v-if="keys.length > 0">
      <div
        role="row"
        class="gl-responsive-table-row table-row-header !gl-border-default gl-bg-subtle gl-text-base gl-font-bold gl-text-strong md:gl-pl-5 md:gl-pr-5"
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
    <div v-else class="gl-bg-subtle gl-p-5 gl-text-subtle" data-testid="empty-state">
      <span v-if="hasSearch">{{ s__('DeployKeys|No search results found.') }}</span>
      <span v-else>{{
        s__('DeployKeys|No deploy keys found, start by adding a new one above.')
      }}</span>
    </div>
  </div>
</template>
