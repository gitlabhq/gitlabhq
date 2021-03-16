<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

export default {
  name: 'PersistedDropdownSelection',
  components: {
    GlDropdown,
    GlDropdownItem,
    LocalStorageSync,
  },
  props: {
    options: {
      type: Array,
      required: true,
    },
    storageKey: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selected: null,
    };
  },
  computed: {
    dropdownText() {
      const selected = this.parsedOptions.find((o) => o.selected);
      return selected?.label || this.options[0].label;
    },
    parsedOptions() {
      return this.options.map((o) => ({ ...o, selected: o.value === this.selected }));
    },
  },
  methods: {
    setSelected(value) {
      this.selected = value;
      this.$emit('change', value);
    },
  },
};
</script>

<template>
  <local-storage-sync :storage-key="storageKey" :value="selected" @input="setSelected">
    <gl-dropdown :text="dropdownText" lazy>
      <gl-dropdown-item
        v-for="option in parsedOptions"
        :key="option.value"
        :is-checked="option.selected"
        :is-check-item="true"
        @click="setSelected(option.value)"
      >
        {{ option.label }}
      </gl-dropdown-item>
    </gl-dropdown>
  </local-storage-sync>
</template>
