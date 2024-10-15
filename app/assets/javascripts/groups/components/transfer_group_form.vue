<script>
import { __, s__ } from '~/locale';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import TransferLocations from '~/groups_projects/components/transfer_locations.vue';
import { getGroupTransferLocations } from '~/api/groups_api';

export const i18n = {
  confirmationMessage: __(
    "You are about to transfer %{codeStart}%{groupName}%{codeEnd} to another namespace. This action changes the %{groupLinkStart}group's path%{groupLinkEnd} and can lead to %{documentationLinkStart}data loss%{documentationLinkEnd}.",
  ),
  confirmButtonText: __('Transfer group'),
  emptyNamespaceTitle: __('No parent group'),
  dropdownLabel: s__('GroupSettings|Select parent group'),
};

export default {
  name: 'TransferGroupForm',
  components: {
    ConfirmDanger,
    TransferLocations,
  },
  props: {
    isPaidGroup: {
      type: Boolean,
      required: true,
    },
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
    disableSubmitButton() {
      return this.isPaidGroup || !this.selectedTransferLocation;
    },
    selectedTransferLocationId() {
      return this.selectedTransferLocation?.id;
    },
  },
  methods: {
    getGroupTransferLocations,
  },
  i18n,
  additionalDropdownItems: [
    {
      id: -1,
      humanName: i18n.emptyNamespaceTitle,
    },
  ],
};
</script>
<template>
  <div>
    <input type="hidden" name="new_parent_group_id" :value="selectedTransferLocationId" />
    <transfer-locations
      v-if="!isPaidGroup"
      v-model="selectedTransferLocation"
      :show-user-transfer-locations="false"
      data-testid="transfer-group-namespace"
      :group-transfer-locations-api-method="getGroupTransferLocations"
      :additional-dropdown-items="$options.additionalDropdownItems"
      :label="$options.i18n.dropdownLabel"
    />
    <confirm-danger
      :disabled="disableSubmitButton"
      :phrase="confirmationPhrase"
      :button-text="confirmButtonText"
      button-testid="transfer-group-button"
      @confirm="$emit('confirm')"
    />
  </div>
</template>
