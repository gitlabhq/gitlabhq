<script>
import { GlFormGroup, GlFormInput, GlModal } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlModal,
    GlFormGroup,
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
  modal: {
    actionPrimary: {
      text: __('Update'),
      attributes: { category: 'primary', variant: 'confirm' },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
};
</script>

<template>
  <gl-modal
    :modal-id="modalId"
    :title="s__('Pipelines|Update Trigger')"
    :action-primary="$options.modal.actionPrimary"
    :action-secondary="$options.modal.actionSecondary"
    @change="$emit('change', $event)"
    @primary="onSubmit"
  >
    <gl-form-group :label="s__('Pipelines|Token')" label-for="edit_trigger_token">
      <p id="edit_trigger_token" class="gl-text-subtle">{{ triggerModel.token }}</p>
    </gl-form-group>
    <gl-form-group :label="s__('Pipelines|Description')" label-for="edit_trigger_description">
      <gl-form-input id="edit_trigger_description" v-model="triggerModel.description" />
    </gl-form-group>
  </gl-modal>
</template>
