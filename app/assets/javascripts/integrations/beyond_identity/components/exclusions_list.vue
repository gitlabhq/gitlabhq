<script>
import { GlButton, GlEmptyState } from '@gitlab/ui';
import { sortBy } from 'lodash';
import { s__, __ } from '~/locale';
import globalToast from '~/vue_shared/plugins/global_toast';
import ExclusionsTabs from './exclusions_tabs.vue';
import ExclusionsListItem from './exclusions_list_item.vue';
import AddExclusionsDrawer from './add_exclusions_drawer.vue';
import ConfirmRemovalModal from './remove_exclusion_confirmation_modal.vue';

export default {
  name: 'ExclusionsList',
  components: {
    GlButton,
    GlEmptyState,
    ExclusionsTabs,
    ExclusionsListItem,
    AddExclusionsDrawer,
    ConfirmRemovalModal,
  },
  data() {
    return {
      isDrawerOpen: false,
      isConfirmRemovalModalOpen: false,
      exclusions: [],
      exclusionToRemove: null,
    };
  },
  computed: {
    formattedExclusions() {
      return sortBy(
        this.exclusions.map((exclusion) => ({
          ...exclusion,
          icon: exclusion.type,
        })),
        'name',
      );
    },
  },
  created() {
    this.loadExclusions();
  },
  methods: {
    loadExclusions() {
      // TODO: add backend call for GET/Query (follow-up)
      this.exclusions = [];
    },
    handleAddExclusions(exclusions) {
      // TODO: add backend call for POST/Mutate (follow-up)
      this.exclusions.push(...exclusions);
      this.isDrawerOpen = false;
    },
    showRemoveModal(exclusion) {
      this.exclusionToRemove = exclusion;
      this.isConfirmRemovalModalOpen = true;
    },
    hideRemoveModal() {
      this.isConfirmRemovalModalOpen = false;
    },
    confirmRemoveExclusion() {
      const { exclusionToRemove } = this;
      // TODO: add backend call for DELETE/Mutate (follow-up)
      this.exclusions = this.exclusions.filter((item) => item.id !== exclusionToRemove.id);

      globalToast(this.$options.i18n.exclusionRemoved, {
        action: {
          text: __('Undo'),
          onClick: (_, toast) => {
            this.handleAddExclusions([exclusionToRemove]);
            toast.hide();
          },
        },
      });
    },
    toggleDrawer() {
      this.isDrawerOpen = !this.isDrawerOpen;
    },
  },
  i18n: {
    exclusionRemoved: s__('Integrations|Project exclusion removed'),
    emptyText: s__('Integrations|There are no exclusions'),
    addExclusions: s__('Integrations|Add exclusions'),
    helpText: s__('Integrations|Projects in this list no longer require commits to be signed.'),
  },
};
</script>

<template>
  <div>
    <exclusions-tabs />

    <div
      class="gl-display-flex gl-justify-content-space-between gl-bg-gray-10 gl-p-4 gl-py-5 gl-border-b gl-align-items-center"
    >
      <span>{{ $options.i18n.helpText }}</span>
      <gl-button variant="confirm" @click="isDrawerOpen = true">{{
        $options.i18n.addExclusions
      }}</gl-button>
    </div>

    <gl-empty-state v-if="!exclusions.length" :title="$options.i18n.emptyText" />

    <exclusions-list-item
      v-for="(exclusion, index) in formattedExclusions"
      v-else
      :key="index"
      :exclusion="exclusion"
      @remove="() => showRemoveModal(exclusion)"
    />

    <add-exclusions-drawer
      :is-open="isDrawerOpen"
      @close="isDrawerOpen = false"
      @add="handleAddExclusions"
    />

    <confirm-removal-modal
      v-if="exclusionToRemove && isConfirmRemovalModalOpen"
      :visible="isConfirmRemovalModalOpen"
      :name="exclusionToRemove.name"
      :type="exclusionToRemove.type"
      @primary="confirmRemoveExclusion"
      @hide="hideRemoveModal"
    />
  </div>
</template>
