<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import Mousetrap from 'mousetrap';
import { ApolloMutation } from 'vue-apollo';
import { keysFor, ISSUE_CLOSE_DESIGN } from '~/behaviors/shortcuts/keybindings';
import createFlash from '~/flash';
import { fetchPolicies } from '~/lib/graphql';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DesignDestroyer from '../../components/design_destroyer.vue';
import DesignReplyForm from '../../components/design_notes/design_reply_form.vue';
import DesignPresentation from '../../components/design_presentation.vue';
import DesignScaler from '../../components/design_scaler.vue';
import DesignSidebar from '../../components/design_sidebar.vue';
import Toolbar from '../../components/toolbar/index.vue';
import { ACTIVE_DISCUSSION_SOURCE_TYPES, DESIGN_DETAIL_LAYOUT_CLASSLIST } from '../../constants';
import createImageDiffNoteMutation from '../../graphql/mutations/create_image_diff_note.mutation.graphql';
import repositionImageDiffNoteMutation from '../../graphql/mutations/reposition_image_diff_note.mutation.graphql';
import updateActiveDiscussionMutation from '../../graphql/mutations/update_active_discussion.mutation.graphql';
import getDesignQuery from '../../graphql/queries/get_design.query.graphql';
import allVersionsMixin from '../../mixins/all_versions';
import { DESIGNS_ROUTE_NAME } from '../../router/constants';
import {
  updateStoreAfterAddImageDiffNote,
  updateStoreAfterRepositionImageDiffNote,
} from '../../utils/cache_update';
import {
  extractDiscussions,
  extractDesign,
  repositionImageDiffNoteOptimisticResponse,
  toDiffNoteGid,
  extractDesignNoteId,
  getPageLayoutElement,
} from '../../utils/design_management_utils';
import {
  ADD_DISCUSSION_COMMENT_ERROR,
  ADD_IMAGE_DIFF_NOTE_ERROR,
  UPDATE_IMAGE_DIFF_NOTE_ERROR,
  DESIGN_NOT_FOUND_ERROR,
  DESIGN_VERSION_NOT_EXIST_ERROR,
  UPDATE_NOTE_ERROR,
  TOGGLE_TODO_ERROR,
  designDeletionError,
} from '../../utils/error_messages';
import { trackDesignDetailView, servicePingDesignDetailView } from '../../utils/tracking';

const DEFAULT_SCALE = 1;

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
  mixins: [allVersionsMixin, glFeatureFlagsMixin()],
  beforeRouteUpdate(to, from, next) {
    // reset scale when the active design changes
    this.scale = DEFAULT_SCALE;
    next();
  },
  beforeRouteEnter(to, from, next) {
    const pageEl = getPageLayoutElement();
    if (pageEl) {
      pageEl.classList.add(...DESIGN_DETAIL_LAYOUT_CLASSLIST);
    }

    next();
  },
  beforeRouteLeave(to, from, next) {
    const pageEl = getPageLayoutElement();
    if (pageEl) {
      pageEl.classList.remove(...DESIGN_DETAIL_LAYOUT_CLASSLIST);
    }

    next();
  },
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
      errorMessage: '',
      scale: DEFAULT_SCALE,
      resolvedDiscussionsExpanded: false,
    };
  },
  apollo: {
    design: {
      query: getDesignQuery,
      // We want to see cached design version if we have one, and fetch newer version on the background to update discussions
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      variables() {
        return this.designVariables;
      },
      update: (data) => extractDesign(data),
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
      return this.discussions.filter((discussion) => discussion.resolved);
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
    Mousetrap.bind(keysFor(ISSUE_CLOSE_DESIGN), this.closeDesign);
    this.trackPageViewEvent();

    // Set active discussion immediately.
    // This will ensure that, if a note is specified in the URL hash,
    // the browser will scroll to, and highlight, the note in the UI
    this.updateActiveDiscussionFromUrl();
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(ISSUE_CLOSE_DESIGN));
  },
  methods: {
    addImageDiffNoteToStore(store, { data: { createImageDiffNote } }) {
      updateStoreAfterAddImageDiffNote(
        store,
        createImageDiffNote,
        getDesignQuery,
        this.designVariables,
      );
    },
    updateImageDiffNoteInStore(store, { data: { repositionImageDiffNote } }) {
      return updateStoreAfterRepositionImageDiffNote(
        store,
        repositionImageDiffNote,
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
        optimisticResponse: repositionImageDiffNoteOptimisticResponse(note, {
          position,
        }),
        variables: {
          input: {
            id: noteId,
            position,
          },
        },
        mutation: repositionImageDiffNoteMutation,
        update: this.updateImageDiffNoteInStore,
      };

      return this.$apollo.mutate(mutationPayload).catch((e) => this.onUpdateImageDiffNoteError(e));
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
      createFlash({ message });
      this.$router.push({ name: this.$options.DESIGNS_ROUTE_NAME });
    },
    onError(message, e) {
      this.errorMessage = message;
      if (e) throw e;
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
    onTodoError(e) {
      this.onError(e?.message || TOGGLE_TODO_ERROR, e);
    },
    openCommentForm(annotationCoordinates) {
      this.annotationCoordinates = annotationCoordinates;
      if (this.$refs.newDiscussionForm) {
        this.$refs.newDiscussionForm.focusInput();
      }
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
    trackPageViewEvent() {
      // TODO: This needs to be made aware of referers, or if it's rendered in a different context than a Issue
      trackDesignDetailView(
        'issue-design-collection',
        'issue',
        this.$route.query.version || this.latestVersionId,
        this.isLatestVersion,
      );

      if (this.glFeatures.usageDataDesignAction) {
        servicePingDesignDetailView();
      }
    },
    updateActiveDiscussion(id, source = ACTIVE_DISCUSSION_SOURCE_TYPES.discussion) {
      this.$apollo.mutate({
        mutation: updateActiveDiscussionMutation,
        variables: {
          id,
          source,
        },
      });
    },
    updateActiveDiscussionFromUrl() {
      const noteId = extractDesignNoteId(this.$route.hash);
      const diffNoteGid = noteId ? toDiffNoteGid(noteId) : undefined;
      return this.updateActiveDiscussion(diffNoteGid, ACTIVE_DISCUSSION_SOURCE_TYPES.url);
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
    class="design-detail js-design-detail fixed-top gl-w-full gl-bottom-0 gl-display-flex gl-justify-content-center gl-flex-direction-column gl-lg-flex-direction-row"
  >
    <gl-loading-icon v-if="isFirstLoading" size="xl" class="gl-align-self-center" />
    <template v-else>
      <div
        class="gl-display-flex gl-overflow-hidden gl-flex-grow-1 gl-flex-direction-column gl-relative"
      >
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

        <div v-if="errorMessage" class="gl-p-5">
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

        <div
          class="design-scaler-wrapper gl-absolute gl-mb-6 gl-display-flex gl-justify-content-center gl-align-items-center"
        >
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
        @todoError="onTodoError"
      >
        <template #reply-form>
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
              ref="newDiscussionForm"
              v-model="comment"
              :is-saving="loading"
              :markdown-preview-path="markdownPreviewPath"
              @submit-form="mutate"
              @cancel-form="closeCommentForm"
            /> </apollo-mutation
        ></template>
      </design-sidebar>
    </template>
  </div>
</template>
