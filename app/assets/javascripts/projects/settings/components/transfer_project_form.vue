<script>
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import TransferLocations from '~/groups_projects/components/transfer_locations.vue';
import { getTransferLocations } from '~/api/projects_api';

export default {
  name: 'TransferProjectForm',
  components: {
    TransferLocations,
    ConfirmDanger,
  },
  props: {
    confirmationPhrase: {
      type: String,
      required: true,
    },
    confirmButtonText: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedTransferLocation: null,
    };
  },

  computed: {
    hasSelectedNamespace() {
      return Boolean(this.selectedTransferLocation?.id);
    },
  },
  watch: {
    selectedTransferLocation(selectedTransferLocation) {
      this.$emit('selectTransferLocation', selectedTransferLocation.id);
    },
  },
  methods: {
    getTransferLocations,
  },
};
</script>
<template>
  <div>
    <transfer-locations
      v-model="selectedTransferLocation"
      data-testid="transfer-project-namespace"
      :group-transfer-locations-api-method="getTransferLocations"
    />
    <confirm-danger
      :disabled="!hasSelectedNamespace"
      :phrase="confirmationPhrase"
      :button-text="confirmButtonText"
      button-testid="transfer-project-button"
      @confirm="$emit('confirm')"
    />
  </div>
</template>
