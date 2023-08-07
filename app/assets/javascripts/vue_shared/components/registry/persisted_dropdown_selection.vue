<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

export default {
  name: 'PersistedDropdownSelection',
  components: {
    GlCollapsibleListbox,
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
      selected: this.options[0].value,
    };
  },
  computed: {
    listboxItems() {
      return this.options.map((option) => ({
        value: option.value,
        text: option.label,
      }));
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
  <local-storage-sync :storage-key="storageKey" :value="selected" as-string @input="setSelected">
    <gl-collapsible-listbox v-model="selected" :items="listboxItems" @select="setSelected" />
  </local-storage-sync>
</template>
