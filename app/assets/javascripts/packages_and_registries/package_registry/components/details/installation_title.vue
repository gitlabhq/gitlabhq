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
    <h2 class="gl-heading-2">{{ __('Installation') }}</h2>
    <div>
      <persisted-dropdown-selection
        :storage-key="storageKey"
        :options="options"
        @change="$emit('change', $event)"
      />
    </div>
  </div>
</template>
