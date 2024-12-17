<script>
import { s__ } from '~/locale';
import IssuableDescription from '~/vue_shared/issuable/show/components/issuable_description.vue';

export default {
  name: 'ModelDetail',
  components: {
    IssuableDescription,
  },
  provide() {
    return {
      importPath: '',
    };
  },
  inject: ['createModelVersionPath'],
  props: {
    model: {
      type: Object,
      required: true,
    },
    taskListUpdatePath: {
      type: String,
      required: false,
      default: '',
    },
    dataUpdateUrl: {
      type: String,
      required: false,
      default: null,
    },
    canEditRequirement: {
      type: Boolean,
      required: false,
      default: false,
    },
    enableTaskList: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    versionCount() {
      return this.model.versionCount || 0;
    },
    issuable() {
      return {
        titleHtml: this.model.name,
        descriptionHtml: this.model.descriptionHtml,
      };
    },
  },
  emptyState: {
    modelCardDescription: s__(
      'MlModelRegistry|No description available. To add a description, click "Edit model" above.',
    ),
  },
};
</script>

<template>
  <div class="issue-details issuable-details">
    <div
      v-if="model.descriptionHtml"
      class="detail-page-description js-detail-page-description gl-pt-4"
    >
      <issuable-description
        :issuable="issuable"
        :enable-task-list="enableTaskList"
        :can-edit="canEditRequirement"
        :data-update-url="dataUpdateUrl"
        :task-list-update-path="taskListUpdatePath"
      />
    </div>
    <div v-else class="gl-text-subtle" data-testid="empty-description-state">
      {{ $options.emptyState.modelCardDescription }}
    </div>
  </div>
</template>
