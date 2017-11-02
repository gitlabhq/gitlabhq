<script>
  import issuableApp from '~/issue_show/components/app.vue';
  import epicHeader from './epic_header.vue';

  export default {
    name: 'epicShowApp',
    props: {
      endpoint: {
        type: String,
        required: true,
      },
      canUpdate: {
        required: true,
        type: Boolean,
      },
      canDestroy: {
        required: true,
        type: Boolean,
      },
      markdownPreviewPath: {
        type: String,
        required: true,
      },
      markdownDocsPath: {
        type: String,
        required: true,
      },
      groupPath: {
        type: String,
        required: true,
      },
      initialTitleHtml: {
        type: String,
        required: true,
      },
      initialTitleText: {
        type: String,
        required: true,
      },
      initialDescriptionHtml: {
        type: String,
        required: false,
        default: '',
      },
      initialDescriptionText: {
        type: String,
        required: false,
        default: '',
      },
      created: {
        type: String,
        required: true,
      },
      author: {
        type: Object,
        required: true,
      },
    },
    components: {
      epicHeader,
      issuableApp,
    },
    created() {
      // Epics specific configuration
      this.issuableRef = '';
      this.projectPath = this.groupPath;
      this.projectNamespace = '';
    },
  };
</script>

<template>
  <div>
    <epic-header
      :author="author"
      :created="created"
    />
    <div class="issuable-details detail-page-description content-block">
      <issuable-app
        :can-update="canUpdate"
        :can-destroy="canDestroy"
        :endpoint="endpoint"
        :issuable-ref="issuableRef"
        :initial-title-html="initialTitleHtml"
        :initial-title-text="initialTitleText"
        :initial-description-html="initialDescriptionHtml"
        :initial-description-text="initialDescriptionText"
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
        :project-path="projectPath"
        :project-namespace="projectNamespace"
        :show-inline-edit-button="true"
      />
    </div>
  </div>
</template>
