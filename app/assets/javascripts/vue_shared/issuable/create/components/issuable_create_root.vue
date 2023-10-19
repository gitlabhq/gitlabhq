<script>
import IssuableForm from './issuable_form.vue';

export default {
  components: {
    IssuableForm,
  },
  props: {
    descriptionPreviewPath: {
      type: String,
      required: true,
    },
    descriptionHelpPath: {
      type: String,
      required: true,
    },
    labelsFetchPath: {
      type: String,
      required: true,
    },
    labelsManagePath: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="issuable-create-container">
    <slot name="title"></slot>
    <issuable-form
      :description-preview-path="descriptionPreviewPath"
      :description-help-path="descriptionHelpPath"
      :labels-fetch-path="labelsFetchPath"
      :labels-manage-path="labelsManagePath"
      :issuable-type="issuableType"
    >
      <template #actions="issuableMeta">
        <slot name="actions" v-bind="issuableMeta"></slot>
      </template>
    </issuable-form>
  </div>
</template>
