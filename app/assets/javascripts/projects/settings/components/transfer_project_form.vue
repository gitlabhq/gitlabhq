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
    showUserTransferLocations: {
      type: Boolean,
      required: false,
      default: true,
    },
    targetFormId: {
      type: String,
      required: true,
    },
    targetHiddenInputId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedTransferLocation: null,
      confirmLoading: false,
    };
  },

  computed: {
    hasSelectedNamespace() {
      return Boolean(this.selectedTransferLocation?.id);
    },
  },
  watch: {
    selectedTransferLocation({ id }) {
      const hiddenInput = document.getElementById(this.targetHiddenInputId);
      if (hiddenInput) hiddenInput.value = id;
    },
  },
  methods: {
    getTransferLocations,
    onConfirm(event) {
      const form = document.getElementById(this.targetFormId);
      if (!form) return;

      // Keep the modal open with the confirm button in its loading state while
      // the synchronous form submit runs; the transfer can take a while.
      event?.preventDefault();
      this.confirmLoading = true;
      try {
        form.submit();
      } catch {
        this.confirmLoading = false;
      }
    },
  },
};
</script>
<template>
  <div>
    <transfer-locations
      v-model="selectedTransferLocation"
      data-testid="transfer-project-namespace"
      :group-transfer-locations-api-method="getTransferLocations"
      :show-user-transfer-locations="showUserTransferLocations"
    />
    <confirm-danger
      :disabled="!hasSelectedNamespace"
      :phrase="confirmationPhrase"
      :button-text="confirmButtonText"
      :confirm-loading="confirmLoading"
      button-testid="transfer-project-button"
      @confirm="onConfirm"
    />
  </div>
</template>
