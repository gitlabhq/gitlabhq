<script>
import { GlButton } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import ReconciliationModal from './modal.vue';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'GroupSettingsCreateOrganization',
  components: {
    GlButton,
    ReconciliationModal,
  },
  mixins: [trackingMixin],
  props: {
    groupFullPath: {
      type: String,
      required: true,
    },
    groupGid: {
      type: String,
      required: true,
    },
    groupOrganization: {
      type: Object,
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
      this.trackEvent('click_create_organization_from_group_settings');
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
      :group-organization="groupOrganization"
    />
  </div>
</template>
