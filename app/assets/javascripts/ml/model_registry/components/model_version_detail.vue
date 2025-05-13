<script>
import IssuableDescription from '~/vue_shared/issuable/show/components/issuable_description.vue';
import { s__ } from '~/locale';

export default {
  name: 'ModelVersionDetail',
  components: {
    IssuableDescription,
  },
  props: {
    modelVersion: {
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
    issuable() {
      return {
        titleHtml: this.modelVersion.name,
        descriptionHtml: this.modelVersion.descriptionHtml,
      };
    },
  },
  i18n: {
    EMPTY_VERSION_CARD_DESCRIPTION: s__(
      'MlModelRegistry|No description available. To add a description, click "Edit model version" above.',
    ),
  },
};
</script>

<template>
  <div class="issue-details issuable-details gl-mt-5">
    <div
      v-if="modelVersion.descriptionHtml"
      class="detail-page-description js-detail-page-description"
    >
      <issuable-description
        data-testid="description"
        :issuable="issuable"
        :enable-task-list="enableTaskList"
        :can-edit="canEditRequirement"
        :data-update-url="dataUpdateUrl"
        :task-list-update-path="taskListUpdatePath"
        class="gl-leading-20"
      />
    </div>
    <div v-else class="gl-text-subtle" data-testid="emptyDescriptionState">
      {{ $options.i18n.EMPTY_VERSION_CARD_DESCRIPTION }}
    </div>
  </div>
</template>
