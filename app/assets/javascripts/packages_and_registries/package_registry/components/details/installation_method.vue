<script>
import { s__ } from '~/locale';
import PersistedRadioGroup from '~/vue_shared/components/registry/persisted_radio_group.vue';

export default {
  name: 'InstallationMethod',
  components: {
    PersistedRadioGroup,
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
  i18n: {
    label: s__('PackageRegistry|Installation Method'),
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <persisted-radio-group
      :storage-key="storageKey"
      :options="options"
      :label="$options.i18n.label"
      @change="$emit('change', $event)"
    />
  </div>
</template>
