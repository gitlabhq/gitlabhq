<script>
import { mapGetters, mapActions } from 'vuex';
import { GlLabel } from '@gitlab/ui';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import { isScopedLabel } from '~/lib/utils/common_utils';
import createFlash from '~/flash';
import { __ } from '~/locale';

export default {
  components: {
    BoardEditableItem,
    LabelsSelect,
    GlLabel,
  },
  data() {
    return {
      loading: false,
    };
  },
  inject: ['labelsFetchPath', 'labelsManagePath', 'labelsFilterBasePath'],
  computed: {
    ...mapGetters(['activeIssue', 'projectPathForActiveIssue']),
    selectedLabels() {
      const { labels = [] } = this.activeIssue;

      return labels.map(label => ({
        ...label,
        id: getIdFromGraphQLId(label.id),
      }));
    },
    issueLabels() {
      const { labels = [] } = this.activeIssue;

      return labels.map(label => ({
        ...label,
        scoped: isScopedLabel(label),
      }));
    },
  },
  methods: {
    ...mapActions(['setActiveIssueLabels']),
    async setLabels(payload) {
      this.loading = true;
      this.$refs.sidebarItem.collapse();

      try {
        const addLabelIds = payload.filter(label => label.set).map(label => label.id);
        const removeLabelIds = this.selectedLabels
          .filter(label => !payload.find(selected => selected.id === label.id))
          .map(label => label.id);

        const input = { addLabelIds, removeLabelIds, projectPath: this.projectPathForActiveIssue };
        await this.setActiveIssueLabels(input);
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
        await this.setActiveIssueLabels(input);
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
