<script>
import { mapState, mapActions } from 'vuex';
import SkeletonLoader from '../components/skeleton_loader.vue';
import EditArea from '../components/edit_area.vue';
import InvalidContentMessage from '../components/invalid_content_message.vue';
import SubmitChangesError from '../components/submit_changes_error.vue';
import { SUCCESS_ROUTE } from '../router/constants';
import appDataQuery from '../graphql/queries/app_data.query.graphql';
import sourceContentQuery from '../graphql/queries/source_content.query.graphql';
import createFlash from '~/flash';
import { LOAD_CONTENT_ERROR } from '../constants';

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
  computed: {
    ...mapState(['isSavingChanges', 'submitChangesError']),
    isLoadingContent() {
      return this.$apollo.queries.sourceContent.loading;
    },
    isContentLoaded() {
      return Boolean(this.sourceContent);
    },
  },
  methods: {
    ...mapActions(['setContent', 'submitChanges', 'dismissSubmitChangesError']),
    onSubmit({ content }) {
      this.setContent(content);

      return this.submitChanges().then(() => this.$router.push(SUCCESS_ROUTE));
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
        @dismiss="dismissSubmitChangesError"
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
