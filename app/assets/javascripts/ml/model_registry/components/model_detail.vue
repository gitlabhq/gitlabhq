<script>
import { GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import IssuableDescription from '~/vue_shared/issuable/show/components/issuable_description.vue';
import { MODEL_VERSION_CREATION_MODAL_ID } from '../constants';
import EmptyState from './model_list_empty_state.vue';

export default {
  name: 'ModelDetail',
  components: {
    IssuableDescription,
    EmptyState,
    GlLink,
  },
  provide() {
    return {
      importPath: '',
    };
  },
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
    title: s__('MlModelRegistry|Manage versions of your machine learning model'),
    description: s__('MlModelRegistry|Use versions to track performance, parameters, and metadata'),
    primaryText: s__('MlModelRegistry|Create model version'),
    modalId: MODEL_VERSION_CREATION_MODAL_ID,
  },
};
</script>

<template>
  <div class="issue-details issuable-details">
    <div v-if="model.latestVersion">
      <h3 class="gl-font-lg">
        {{ s__('MlModelRegistry|Latest version') }}:

        <gl-link :href="model.latestVersion._links.showPath" data-testid="model-version-link">
          {{ model.latestVersion.version }}
        </gl-link>
      </h3>
    </div>
    <div
      v-if="model.descriptionHtml"
      class="detail-page-description js-detail-page-description content-block gl-pt-4"
    >
      <issuable-description
        :issuable="issuable"
        :enable-task-list="enableTaskList"
        :can-edit="canEditRequirement"
        :data-update-url="dataUpdateUrl"
        :task-list-update-path="taskListUpdatePath"
      />
    </div>
    <empty-state
      v-else
      :title="$options.emptyState.title"
      :description="$options.emptyState.description"
      :primary-text="$options.emptyState.primaryText"
      :modal-id="$options.emptyState.modalId"
    />
  </div>
</template>
