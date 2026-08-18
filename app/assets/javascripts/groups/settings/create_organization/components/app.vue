<script>
import { GlButton } from '@gitlab/ui';
import ReconciliationModal from './modal.vue';

export default {
  name: 'GroupSettingsCreateOrganization',
  components: {
    GlButton,
    ReconciliationModal,
  },
  props: {
    groupFullPath: {
      type: String,
      required: true,
    },
    groupGid: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showReconciliationModal: false,
    };
  },
  methods: {
    openReconciliationModal() {
      this.showReconciliationModal = true;
    },
  },
};
</script>

<template>
  <div>
    <gl-button
      variant="confirm"
      data-testid="start-creating-organization-button"
      @click="openReconciliationModal"
      >{{ s__('GroupSettings|Create organization…') }}</gl-button
    >
    <reconciliation-modal
      v-model="showReconciliationModal"
      :group-full-path="groupFullPath"
      :group-gid="groupGid"
    />
  </div>
</template>
