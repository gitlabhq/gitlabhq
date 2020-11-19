<script>
import { deprecatedCreateFlash as createFlash } from '~/flash';
import Tracking from '~/tracking';

import SkeletonLoader from '../components/skeleton_loader.vue';
import EditArea from '../components/edit_area.vue';
import EditMetaModal from '../components/edit_meta_modal.vue';
import InvalidContentMessage from '../components/invalid_content_message.vue';
import SubmitChangesError from '../components/submit_changes_error.vue';
import appDataQuery from '../graphql/queries/app_data.query.graphql';
import sourceContentQuery from '../graphql/queries/source_content.query.graphql';
import hasSubmittedChangesMutation from '../graphql/mutations/has_submitted_changes.mutation.graphql';
import submitContentChangesMutation from '../graphql/mutations/submit_content_changes.mutation.graphql';
import { LOAD_CONTENT_ERROR, TRACKING_ACTION_INITIALIZE_EDITOR } from '../constants';
import { SUCCESS_ROUTE } from '../router/constants';

export default {
  components: {
    SkeletonLoader,
    EditArea,
    EditMetaModal,
    InvalidContentMessage,
    SubmitChangesError,
  },
  apollo: {
    appData: {
      query: appDataQuery,
    },
    sourceContent: {
      query: sourceContentQuery,
      update: ({
        project: {
          file: { title, content },
        },
      }) => {
        return { title, content };
      },
      variables() {
        return {
          project: this.appData.project,
          sourcePath: this.appData.sourcePath,
        };
      },
      skip() {
        return !this.appData.isSupportedContent;
      },
      error() {
        createFlash(LOAD_CONTENT_ERROR);
      },
    },
  },
  data() {
    return {
      content: null,
      images: null,
      submitChangesError: null,
      isSavingChanges: false,
    };
  },
  computed: {
    isLoadingContent() {
      return this.$apollo.queries.sourceContent.loading;
    },
    isContentLoaded() {
      return Boolean(this.sourceContent);
    },
    projectSplit() {
      return this.appData.project.split('/'); // TODO: refactor so `namespace` and `project` remain distinct
    },
  },
  mounted() {
    Tracking.event(document.body.dataset.page, TRACKING_ACTION_INITIALIZE_EDITOR);
  },
  methods: {
    onHideModal() {
      this.isSavingChanges = false;
      this.$refs.editMetaModal.hide();
    },
    onDismissError() {
      this.submitChangesError = null;
    },
    onPrepareSubmit({ content, images }) {
      this.content = content;
      this.images = images;

      this.isSavingChanges = true;
      this.$refs.editMetaModal.show();
    },
    onSubmit(mergeRequestMeta) {
      // eslint-disable-next-line promise/catch-or-return
      this.$apollo
        .mutate({
          mutation: hasSubmittedChangesMutation,
          variables: {
            input: {
              hasSubmittedChanges: true,
            },
          },
        })
        .finally(() => {
          this.$router.push(SUCCESS_ROUTE);
        });

      this.$apollo
        .mutate({
          mutation: submitContentChangesMutation,
          variables: {
            input: {
              project: this.appData.project,
              username: this.appData.username,
              sourcePath: this.appData.sourcePath,
              content: this.content,
              images: this.images,
              mergeRequestMeta,
            },
          },
        })
        .catch(e => {
          this.submitChangesError = e.message;
        })
        .finally(() => {
          this.isSavingChanges = false;
        });
    },
  },
};
</script>
<template>
  <div class="container d-flex gl-flex-direction-column pt-2 h-100">
    <template v-if="appData.isSupportedContent">
      <skeleton-loader v-if="isLoadingContent" class="w-75 gl-align-self-center gl-mt-5" />
      <submit-changes-error
        v-if="submitChangesError"
        :error="submitChangesError"
        @retry="onSubmit"
        @dismiss="onDismissError"
      />
      <edit-area
        v-if="isContentLoaded"
        :title="sourceContent.title"
        :content="sourceContent.content"
        :saving-changes="isSavingChanges"
        :return-url="appData.returnUrl"
        :mounts="appData.mounts"
        :branch="appData.branch"
        :base-url="appData.baseUrl"
        :project="appData.project"
        :image-root="appData.imageUploadPath"
        @submit="onPrepareSubmit"
      />
      <edit-meta-modal
        ref="editMetaModal"
        :source-path="appData.sourcePath"
        :namespace="projectSplit[0]"
        :project="projectSplit[1]"
        @primary="onSubmit"
        @hide="onHideModal"
      />
    </template>

    <invalid-content-message v-else class="w-75" />
  </div>
</template>
