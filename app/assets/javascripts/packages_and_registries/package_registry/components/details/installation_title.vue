<script>
import PersistedDropdownSelection from '~/vue_shared/components/registry/persisted_dropdown_selection.vue';

export default {
  name: 'InstallationTitle',
  components: {
    PersistedDropdownSelection,
  },
  props: {
    packageType: {
      type: String,
      required: true,
    },
    options: {
      type: Array,
      required: true,
    },
  },
  computed: {
    storageKey() {
      return `package_${this.packageType}_installation_instructions`;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-justify-between">
    <h3 class="gl-text-lg">{{ __('Installation') }}</h3>
    <div>
      <persisted-dropdown-selection
        :storage-key="storageKey"
        :options="options"
        @change="$emit('change', $event)"
      />
    </div>
  </div>
</template>
