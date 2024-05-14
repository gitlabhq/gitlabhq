<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';

export default {
  name: 'RemoveExclusionConfirmationModal',
  components: {
    GlModal,
    GlSprintf,
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    name: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  computed: {
    modalTitle() {
      return sprintf(this.$options.i18n.title, { type: this.type });
    },
  },
  i18n: {
    body: s__(
      "Integrations|You're removing an exclusion for %{name}. Are you sure you want to continue?",
    ),
    title: s__('Integrations|Confirm %{type} exclusion removal'),
  },
  modalOptions: {
    actionPrimary: {
      text: s__('Integrations|Remove exclusion'),
      attributes: { variant: 'danger' },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: { category: 'secondary' },
    },
    modalId: 'confirm-remove-exclusion',
  },
};
</script>
<template>
  <gl-modal v-bind="$options.modalOptions" :title="modalTitle" :visible="visible" v-on="$listeners">
    <gl-sprintf :message="$options.i18n.body">
      <template #name>
        <strong>{{ name }}</strong>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>
