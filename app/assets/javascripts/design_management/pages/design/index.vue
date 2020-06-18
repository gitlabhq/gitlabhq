<script>
import Mousetrap from 'mousetrap';
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { ApolloMutation } from 'vue-apollo';
import createFlash from '~/flash';
import { fetchPolicies } from '~/lib/graphql';
import allVersionsMixin from '../../mixins/all_versions';
import Toolbar from '../../components/toolbar/index.vue';
import DesignDestroyer from '../../components/design_destroyer.vue';
import DesignScaler from '../../components/design_scaler.vue';
import DesignPresentation from '../../components/design_presentation.vue';
import DesignReplyForm from '../../components/design_notes/design_reply_form.vue';
import DesignSidebar from '../../components/design_sidebar.vue';
import getDesignQuery from '../../graphql/queries/getDesign.query.graphql';
import appDataQuery from '../../graphql/queries/appData.query.graphql';
import createImageDiffNoteMutation from '../../graphql/mutations/createImageDiffNote.mutation.graphql';
import updateImageDiffNoteMutation from '../../graphql/mutations/updateImageDiffNote.mutation.graphql';
import updateActiveDiscussionMutation from '../../graphql/mutations/update_active_discussion.mutation.graphql';
import {
  extractDiscussions,
  extractDesign,
  updateImageDiffNoteOptimisticResponse,
} from '../../utils/design_management_utils';
import {
  updateStoreAfterAddImageDiffNote,
  updateStoreAfterUpdateImageDiffNote,
} from '../../utils/cache_update';
import {
  ADD_DISCUSSION_COMMENT_ERROR,
  ADD_IMAGE_DIFF_NOTE_ERROR,
  UPDATE_IMAGE_DIFF_NOTE_ERROR,
  DESIGN_NOT_FOUND_ERROR,
  DESIGN_VERSION_NOT_EXIST_ERROR,
  UPDATE_NOTE_ERROR,
  designDeletionError,
} from '../../utils/error_messages';
import { trackDesignDetailView } from '../../utils/tracking';
import { DESIGNS_ROUTE_NAME } from '../../router/constants';
import { ACTIVE_DISCUSSION_SOURCE_TYPES } from '../../constants';

export default {
  components: {
    ApolloMutation,
    DesignReplyForm,
    DesignPresentation,
    DesignScaler,
    DesignDestroyer,
    Toolbar,
    GlLoadingIcon,
    GlAlert,
    DesignSidebar,
  },
  mixins: [allVersionsMixin],
  props: {
    id: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      design: {},
      comment: '',
      annotationCoordinates: null,
      projectPath: '',
      errorMessage: '',
      issueIid: '',
      scale: 1,
      resolvedDiscussionsExpanded: false,
    };
  },
  apollo: {
    appData: {
      query: appDataQuery,
      manual: true,
      result({ data: { projectPath, issueIid } }) {
        this.projectPath = projectPath;
        this.issueIid = issueIid;
      },
    },
    design: {
      query: getDesignQuery,
      // We want to see cached design version if we have one, and fetch newer version on the background to update discussions
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      variables() {
        return this.designVariables;
      },
      update: data => extractDesign(data),
      result(res) {
        this.onDesignQueryResult(res);
      },
      error() {
        this.onQueryError(DESIGN_NOT_FOUND_ERROR);
      },
    },
  },
  computed: {
    isFirstLoading() {
      // We only want to show spinner on initial design load (when opened from a deep link to design)
      // If we already have cached a design, loading shouldn't be indicated to user
      return this.$apollo.queries.design.loading && !this.design.filename;
    },
    discussions() {
      if (!this.design.discussions) {
        return [];
      }
      return extractDiscussions(this.design.discussions);
    },
    markdownPreviewPath() {
      return `/${this.projectPath}/preview_markdown?target_type=Issue`;
    },
    isSubmitButtonDisabled() {
      return this.comment.trim().length === 0;
    },
    designVariables() {
      return {
        fullPath: this.projectPath,
        iid: this.issueIid,
        filenames: [this.$route.params.id],
        atVersion: this.designsVersion,
      };
    },
    mutationPayload() {
      const { x, y, width, height } = this.annotationCoordinates;
      return {
        noteableId: this.design.id,
        body: this.comment,
        position: {
          headSha: this.design.diffRefs.headSha,
          baseSha: this.design.diffRefs.baseSha,
          startSha: this.design.diffRefs.startSha,
          x,
          y,
          width,
          height,
          paths: {
            newPath: this.design.fullPath,
          },
        },
      };
    },
    isAnnotating() {
      return Boolean(this.annotationCoordinates);
    },
    resolvedDiscussions() {
      return this.discussions.filter(discussion => discussion.resolved);
    },
  },
  watch: {
    resolvedDiscussions(val) {
      if (!val.length) {
        this.resolvedDiscussionsExpanded = false;
      }
    },
  },
  mounted() {
    Mousetrap.bind('esc', this.closeDesign);
    this.trackEvent();
    // We need to reset the active discussion when opening a new design
    this.updateActiveDiscussion();
  },
  beforeDestroy() {
    Mousetrap.unbind('esc', this.closeDesign);
  },
  methods: {
    addImageDiffNoteToStore(
      store,
      {
        data: { createImageDiffNote },
      },
    ) {
      updateStoreAfterAddImageDiffNote(
        store,
        createImageDiffNote,
        getDesignQuery,
        this.designVariables,
      );
    },
    updateImageDiffNoteInStore(
      store,
      {
        data: { updateImageDiffNote },
      },
    ) {
      return updateStoreAfterUpdateImageDiffNote(
        store,
        updateImageDiffNote,
        getDesignQuery,
        this.designVariables,
      );
    },
    onMoveNote({ noteId, discussionId, position }) {
      const discussion = this.discussions.find(({ id }) => id === discussionId);
      const note = discussion.notes.find(
        ({ discussion: noteDiscussion }) => noteDiscussion.id === discussionId,
      );

      const mutationPayload = {
        optimisticResponse: updateImageDiffNoteOptimisticResponse(note, {
          position,
        }),
        variables: {
          input: {
            id: noteId,
            position,
          },
        },
        mutation: updateImageDiffNoteMutation,
        update: this.updateImageDiffNoteInStore,
      };

      return this.$apollo.mutate(mutationPayload).catch(e => this.onUpdateImageDiffNoteError(e));
    },
    onDesignQueryResult({ data, loading }) {
      // On the initial load with cache-and-network policy data is undefined while loading is true
      // To prevent throwing an error, we don't perform any logic until loading is false
      if (loading) {
        return;
      }

      if (!data || !extractDesign(data)) {
        this.onQueryError(DESIGN_NOT_FOUND_ERROR);
      } else if (this.$route.query.version && !this.hasValidVersion) {
        this.onQueryError(DESIGN_VERSION_NOT_EXIST_ERROR);
      }
    },
    onQueryError(message) {
      // because we redirect user to /designs (the issue page),
      // we want to create these flashes on the issue page
      createFlash(message);
      this.$router.push({ name: this.$options.DESIGNS_ROUTE_NAME });
    },
    onError(message, e) {
      this.errorMessage = message;
      throw e;
    },
    onCreateImageDiffNoteError(e) {
      this.onError(ADD_IMAGE_DIFF_NOTE_ERROR, e);
    },
    onUpdateNoteError(e) {
      this.onError(UPDATE_NOTE_ERROR, e);
    },
    onDesignDiscussionError(e) {
      this.onError(ADD_DISCUSSION_COMMENT_ERROR, e);
    },
    onUpdateImageDiffNoteError(e) {
      this.onError(UPDATE_IMAGE_DIFF_NOTE_ERROR, e);
    },
    onDesignDeleteError(e) {
      this.onError(designDeletionError({ singular: true }), e);
    },
    onResolveDiscussionError(e) {
      this.onError(UPDATE_IMAGE_DIFF_NOTE_ERROR, e);
    },
    openCommentForm(annotationCoordinates) {
      this.annotationCoordinates = annotationCoordinates;
    },
    closeCommentForm() {
      this.comment = '';
      this.annotationCoordinates = null;
    },
    closeDesign() {
      this.$router.push({
        name: this.$options.DESIGNS_ROUTE_NAME,
        query: this.$route.query,
      });
    },
    trackEvent() {
      // TODO: This needs to be made aware of referers, or if it's rendered in a different context than a Issue
      trackDesignDetailView(
        'issue-design-collection',
        'issue',
        this.$route.query.version || this.latestVersionId,
        this.isLatestVersion,
      );
    },
    updateActiveDiscussion(id) {
      this.$apollo.mutate({
        mutation: updateActiveDiscussionMutation,
        variables: {
          id,
          source: ACTIVE_DISCUSSION_SOURCE_TYPES.discussion,
        },
      });
    },
    toggleResolvedComments() {
      this.resolvedDiscussionsExpanded = !this.resolvedDiscussionsExpanded;
    },
  },
  createImageDiffNoteMutation,
  DESIGNS_ROUTE_NAME,
};
</script>

<template>
  <div
    class="design-detail js-design-detail fixed-top w-100 position-bottom-0 d-flex justify-content-center flex-column flex-lg-row"
  >
    <gl-loading-icon v-if="isFirstLoading" size="xl" class="align-self-center" />
    <template v-else>
      <div class="d-flex overflow-hidden flex-grow-1 flex-column position-relative">
        <design-destroyer
          :filenames="[design.filename]"
          :project-path="projectPath"
          :iid="issueIid"
          @done="$router.push({ name: $options.DESIGNS_ROUTE_NAME })"
          @error="onDesignDeleteError"
        >
          <template #default="{ mutate, loading }">
            <toolbar
              :id="id"
              :is-deleting="loading"
              :is-latest-version="isLatestVersion"
              v-bind="design"
              @delete="mutate"
            />
          </template>
        </design-destroyer>

        <div v-if="errorMessage" class="p-3">
          <gl-alert variant="danger" @dismiss="errorMessage = null">
            {{ errorMessage }}
          </gl-alert>
        </div>
        <design-presentation
          :image="design.image"
          :image-name="design.filename"
          :discussions="discussions"
          :is-annotating="isAnnotating"
          :scale="scale"
          :resolved-discussions-expanded="resolvedDiscussionsExpanded"
          @openCommentForm="openCommentForm"
          @closeCommentForm="closeCommentForm"
          @moveNote="onMoveNote"
        />

        <div class="design-scaler-wrapper position-absolute mb-4 d-flex-center">
          <design-scaler @scale="scale = $event" />
        </div>
      </div>
      <design-sidebar
        :design="design"
        :resolved-discussions-expanded="resolvedDiscussionsExpanded"
        :markdown-preview-path="markdownPreviewPath"
        @onDesignDiscussionError="onDesignDiscussionError"
        @onCreateImageDiffNoteError="onCreateImageDiffNoteError"
        @updateNoteError="onUpdateNoteError"
        @resolveDiscussionError="onResolveDiscussionError"
        @toggleResolvedComments="toggleResolvedComments"
      >
        <template #replyForm>
          <apollo-mutation
            v-if="isAnnotating"
            #default="{ mutate, loading }"
            :mutation="$options.createImageDiffNoteMutation"
            :variables="{
              input: mutationPayload,
            }"
            :update="addImageDiffNoteToStore"
            @done="closeCommentForm"
            @error="onCreateImageDiffNoteError"
          >
            <design-reply-form
              v-model="comment"
              :is-saving="loading"
              :markdown-preview-path="markdownPreviewPath"
              @submitForm="mutate"
              @cancelForm="closeCommentForm"
            /> </apollo-mutation
        ></template>
      </design-sidebar>
    </template>
  </div>
</template>
