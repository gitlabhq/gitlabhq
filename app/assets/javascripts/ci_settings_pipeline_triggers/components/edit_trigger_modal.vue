<script>
import { GlFormGroup, GlFormInput, GlFormText, GlModal } from '@gitlab/ui';

export default {
  components: {
    GlModal,
    GlFormGroup,
    GlFormText,
    GlFormInput,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    trigger: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      triggerModel: { ...this.trigger },
    };
  },
  watch: {
    trigger: {
      handler(newVal) {
        this.triggerModel = { ...newVal };
      },
      deep: true,
      immediate: true,
    },
  },
  methods: {
    onSubmit() {
      this.$emit('submit', this.triggerModel);
    },
  },
};
</script>

<template>
  <gl-modal
    :modal-id="modalId"
    :title="s__('Pipelines|Update Trigger')"
    @change="$emit('change', $event)"
    @primary="onSubmit"
  >
    <gl-form-group :label="s__('Pipelines|Token')" label-for="edit_trigger_token">
      <gl-form-text id="edit_trigger_token">{{ triggerModel.token }}</gl-form-text>
    </gl-form-group>
    <gl-form-group :label="s__('Pipelines|Description')" label-for="edit_trigger_description">
      <gl-form-input id="edit_trigger_description" v-model="triggerModel.description" />
    </gl-form-group>
  </gl-modal>
</template>
