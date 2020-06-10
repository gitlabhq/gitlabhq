<script>
import SkeletonLoader from '../components/skeleton_loader.vue';
import EditArea from '../components/edit_area.vue';
import InvalidContentMessage from '../components/invalid_content_message.vue';
import SubmitChangesError from '../components/submit_changes_error.vue';
import appDataQuery from '../graphql/queries/app_data.query.graphql';
import sourceContentQuery from '../graphql/queries/source_content.query.graphql';
import submitContentChangesMutation from '../graphql/mutations/submit_content_changes.mutation.graphql';
import createFlash from '~/flash';
import Tracking from '~/tracking';
import { LOAD_CONTENT_ERROR, TRACKING_ACTION_INITIALIZE_EDITOR } from '../constants';
import { SUCCESS_ROUTE } from '../router/constants';

export default {
  components: {
    SkeletonLoader,
    EditArea,
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
  },
  mounted() {
    Tracking.event(document.body.dataset.page, TRACKING_ACTION_INITIALIZE_EDITOR);
  },
  methods: {
    onDismissError() {
      this.submitChangesError = null;
    },
    onSubmit({ content }) {
      this.content = content;
      this.submitChanges();
    },
    submitChanges() {
      this.isSavingChanges = true;

      this.$apollo
        .mutate({
          mutation: submitContentChangesMutation,
          variables: {
            input: {
              project: this.appData.project,
              username: this.appData.username,
              sourcePath: this.appData.sourcePath,
              content: this.content,
            },
          },
        })
        .then(() => {
          this.$router.push(SUCCESS_ROUTE);
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
        @retry="submitChanges"
        @dismiss="onDismissError"
      />
      <edit-area
        v-if="isContentLoaded"
        :title="sourceContent.title"
        :content="sourceContent.content"
        :saving-changes="isSavingChanges"
        :return-url="appData.returnUrl"
        @submit="onSubmit"
      />
    </template>

    <invalid-content-message v-else class="w-75" />
  </div>
</template>
