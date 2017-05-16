<script>
  import titleField from './fields/title.vue';
  import descriptionField from './fields/description.vue';
  import editActions from './edit_actions.vue';
  import descriptionTemplate from './fields/description_template.vue';

  export default {
    props: {
      canDestroy: {
        type: Boolean,
        required: true,
      },
      formState: {
        type: Object,
        required: true,
      },
      issuableTemplates: {
        type: Array,
        required: false,
        default: () => [],
      },
      markdownPreviewUrl: {
        type: String,
        required: true,
      },
      markdownDocs: {
        type: String,
        required: true,
      },
    },
    components: {
      titleField,
      descriptionField,
      descriptionTemplate,
      editActions,
    },
    computed: {
      hasIssuableTemplates() {
        return this.issuableTemplates.length !== 0;
      },
    },
  };
</script>

<template>
  <form>
    <div class="row">
      <div
        class="col-sm-4 col-lg-3"
        v-if="hasIssuableTemplates">
        <description-template
          :issuable-templates="issuableTemplates" />
      </div>
      <div
        :class="{
          'col-sm-8 col-lg-9': hasIssuableTemplates,
          'col-xs-12': !hasIssuableTemplates,
        }">
        <title-field
          :form-state="formState"
          :issuable-templates="issuableTemplates" />
      </div>
    </div>
    <description-field
      :form-state="formState"
      :markdown-preview-url="markdownPreviewUrl"
      :markdown-docs="markdownDocs" />
    <edit-actions
      :can-destroy="canDestroy" />
  </form>
</template>
