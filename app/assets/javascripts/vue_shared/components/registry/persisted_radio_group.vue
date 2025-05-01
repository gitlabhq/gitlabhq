<script>
import { GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

export default {
  name: 'PersistedRadioGroup',
  components: {
    GlFormGroup,
    GlFormRadioGroup,
    LocalStorageSync,
  },
  props: {
    options: {
      type: Array,
      required: true,
    },
    label: {
      type: String,
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
    radioOptions() {
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
    <gl-form-group :label="label">
      <gl-form-radio-group v-model="selected" :options="radioOptions" @change="setSelected" />
    </gl-form-group>
  </local-storage-sync>
</template>
