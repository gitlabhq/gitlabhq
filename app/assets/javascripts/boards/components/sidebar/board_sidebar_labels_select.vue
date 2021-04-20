<script>
import { GlLabel } from '@gitlab/ui';
import { mapGetters, mapActions } from 'vuex';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import createFlash from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';

export default {
  components: {
    BoardEditableItem,
    LabelsSelect,
    GlLabel,
  },
  inject: ['labelsFetchPath', 'labelsManagePath', 'labelsFilterBasePath'],
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    ...mapGetters(['activeBoardItem', 'projectPathForActiveIssue']),
    selectedLabels() {
      const { labels = [] } = this.activeBoardItem;

      return labels.map((label) => ({
        ...label,
        id: getIdFromGraphQLId(label.id),
      }));
    },
    issueLabels() {
      const { labels = [] } = this.activeBoardItem;

      return labels.map((label) => ({
        ...label,
        scoped: isScopedLabel(label),
      }));
    },
  },
  methods: {
    ...mapActions(['setActiveBoardItemLabels']),
    async setLabels(payload) {
      this.loading = true;
      this.$refs.sidebarItem.collapse();

      try {
        const addLabelIds = payload.filter((label) => label.set).map((label) => label.id);
        const removeLabelIds = this.selectedLabels
          .filter((label) => !payload.find((selected) => selected.id === label.id))
          .map((label) => label.id);

        const input = { addLabelIds, removeLabelIds, projectPath: this.projectPathForActiveIssue };
        await this.setActiveBoardItemLabels(input);
      } catch (e) {
        createFlash({ message: __('An error occurred while updating labels.') });
      } finally {
        this.loading = false;
      }
    },
    async removeLabel(id) {
      this.loading = true;

      try {
        const removeLabelIds = [getIdFromGraphQLId(id)];
        const input = { removeLabelIds, projectPath: this.projectPathForActiveIssue };
        await this.setActiveBoardItemLabels(input);
      } catch (e) {
        createFlash({ message: __('An error occurred when removing the label.') });
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <board-editable-item ref="sidebarItem" :title="__('Labels')" :loading="loading">
    <template #collapsed>
      <gl-label
        v-for="label in issueLabels"
        :key="label.id"
        :background-color="label.color"
        :title="label.title"
        :description="label.description"
        :scoped="label.scoped"
        :show-close-button="true"
        :disabled="loading"
        class="gl-mr-2 gl-mb-2"
        @close="removeLabel(label.id)"
      />
    </template>
    <template #default="{ edit }">
      <labels-select
        ref="labelsSelect"
        :allow-label-edit="false"
        :allow-label-create="false"
        :allow-multiselect="true"
        :allow-scoped-labels="true"
        :selected-labels="selectedLabels"
        :labels-fetch-path="labelsFetchPath"
        :labels-manage-path="labelsManagePath"
        :labels-filter-base-path="labelsFilterBasePath"
        :labels-list-title="__('Select label')"
        :dropdown-button-text="__('Choose labels')"
        :is-editing="edit"
        variant="embedded"
        class="gl-display-block labels gl-w-full"
        @updateSelectedLabels="setLabels"
      >
        {{ __('None') }}
      </labels-select>
    </template>
  </board-editable-item>
</template>
