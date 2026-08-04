<script>
import { GlButton } from '@gitlab/ui';
import ReconciliationModal from '~/organizations/index/components/reconciliation/modal.vue';

export default {
  name: 'GroupSettingsCreateOrganization',
  components: {
    GlButton,
    ReconciliationModal,
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
    <reconciliation-modal v-model="showReconciliationModal" />
  </div>
</template>
