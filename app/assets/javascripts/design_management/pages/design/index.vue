<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlAlert } from '@gitlab/ui';
import { isNull } from 'lodash';
import { Mousetrap } from '~/lib/mousetrap';
import { keysFor, ISSUE_CLOSE_DESIGN } from '~/behaviors/shortcuts/keybindings';
import { createAlert } from '~/alert';
import { fetchPolicies } from '~/lib/graphql';
import { updateGlobalTodoCount } from '~/sidebar/utils';
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
  UPDATE_IMAGE_DIFF_NOTE_ERROR,
  DESIGN_NOT_FOUND_ERROR,
  DESIGN_VERSION_NOT_EXIST_ERROR,
  TOGGLE_TODO_ERROR,
  DELETE_NOTE_ERROR,
  designDeletionError,
} from '../../utils/error_messages';
import { trackDesignDetailView, servicePingDesignDetailView } from '../../utils/tracking';

const DEFAULT_SCALE = 1;
const DEFAULT_MAX_SCALE = 2;

export default {
  components: {
    DesignReplyForm,
    DesignPresentation,
    DesignScaler,
    DesignDestroyer,
    Toolbar,
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
      annotationCoordinates: null,
      errorMessage: '',
      scale: DEFAULT_SCALE,
      resolvedDiscussionsExpanded: false,
      prevCurrentUserTodos: null,
      maxScale: DEFAULT_MAX_SCALE,
      isSidebarOpen: true,
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
    isLoading() {
      return this.$apollo.queries.design.loading;
    },
    discussions() {
      if (!this.design.discussions) {
        return [];
      }
      return extractDiscussions(this.design.discussions);
    },
    markdownPreviewPath() {
      return `/${this.projectPath}/-/preview_markdown?target_type=Issue`;
    },
    designVariables() {
      return {
        fullPath: this.projectPath,
        iid: this.issueIid,
        filenames: [this.$route.params.id],
        atVersion: this.designsVersion,
      };
    },
    mutationVariables() {
      const { x, y, width, height } = this.annotationCoordinates;
      return {
        noteableId: this.design.id,
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
    currentUserTodos() {
      if (!this.design || !this.design.currentUserTodos) {
        return null;
      }

      return this.design.currentUserTodos?.nodes?.length;
    },
  },
  watch: {
    resolvedDiscussions(val) {
      if (!val.length) {
        this.resolvedDiscussionsExpanded = false;
      }
    },
    currentUserTodos(_, prevCurrentUserTodos) {
      this.prevCurrentUserTodos = prevCurrentUserTodos;
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
    addImageDiffNoteToStore({ data }) {
      const { createImageDiffNote } = data;
      /**
       * https://gitlab.com/gitlab-org/gitlab/-/issues/388314
       *
       * The getClient method is not documented. In future,
       * need to check for any alternative.
       */
      const { cache } = this.$apollo.getClient();

      updateStoreAfterAddImageDiffNote(
        cache,
        createImageDiffNote,
        getDesignQuery,
        this.designVariables,
      );
      this.closeCommentForm(data);
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
      // we want to create these alerts on the issue page
      createAlert({ message });
      this.$router.push({ name: this.$options.DESIGNS_ROUTE_NAME });
    },
    onError(message, e) {
      this.errorMessage = message;
      if (e) throw e;
    },
    onDeleteNoteError(e) {
      this.onError(DELETE_NOTE_ERROR, e);
    },
    onUpdateImageDiffNoteError(e) {
      this.onError(UPDATE_IMAGE_DIFF_NOTE_ERROR, e);
    },
    onDesignDeleteError(e) {
      this.onError(designDeletionError(), e);
    },
    onResolveDiscussionError(e) {
      this.onError(UPDATE_IMAGE_DIFF_NOTE_ERROR, e);
    },
    onTodoError(e) {
      this.onError(e?.message || TOGGLE_TODO_ERROR, e);
    },
    openCommentForm(annotationCoordinates) {
      this.annotationCoordinates = annotationCoordinates;
    },
    closeCommentForm(data) {
      this.annotationCoordinates = null;

      if (data?.data && !isNull(this.prevCurrentUserTodos)) {
        updateGlobalTodoCount(this.currentUserTodos - this.prevCurrentUserTodos);
        this.prevCurrentUserTodos = this.currentUserTodos;
      }
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

      servicePingDesignDetailView();
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
    toggleResolvedComments(newValue) {
      this.resolvedDiscussionsExpanded = newValue;
    },
    setMaxScale(event) {
      this.maxScale = 1 / event;
    },
    toggleSidebar() {
      this.isSidebarOpen = !this.isSidebarOpen;
    },
  },
  createImageDiffNoteMutation,
  DESIGNS_ROUTE_NAME,
};
</script>

<template>
  <div
    class="design-detail js-design-detail fixed-top gl-flex gl-w-full gl-flex-col gl-justify-center gl-bg-subtle lg:gl-flex-row"
  >
    <div class="gl-relative gl-flex gl-grow gl-flex-col gl-overflow-hidden">
      <design-destroyer
        :filenames="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
          design.filename,
        ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
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
            :is-loading="isLoading"
            :design="design"
            :is-sidebar-open="isSidebarOpen"
            v-bind="design"
            @delete="mutate"
            @toggle-sidebar="toggleSidebar"
          />
        </template>
      </design-destroyer>

      <div class="gl-relative gl-flex gl-grow gl-flex-col gl-overflow-hidden lg:gl-flex-row">
        <div class="gl-relative gl-flex gl-grow-2 gl-flex-col gl-overflow-hidden">
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
            :is-loading="isLoading"
            :disable-commenting="!isSidebarOpen"
            @openCommentForm="openCommentForm"
            @closeCommentForm="closeCommentForm"
            @moveNote="onMoveNote"
            @setMaxScale="setMaxScale"
          />

          <div
            class="design-scaler-wrapper gl-absolute gl-mb-6 gl-flex gl-items-center gl-justify-center"
          >
            <design-scaler :max-scale="maxScale" @scale="scale = $event" />
          </div>
        </div>
        <design-sidebar
          :design="design"
          :design-variables="designVariables"
          :resolved-discussions-expanded="resolvedDiscussionsExpanded"
          :markdown-preview-path="markdownPreviewPath"
          :is-loading="isLoading"
          :is-open="isSidebarOpen"
          @deleteNoteError="onDeleteNoteError"
          @resolveDiscussionError="onResolveDiscussionError"
          @toggleResolvedComments="toggleResolvedComments"
          @todoError="onTodoError"
        >
          <template #reply-form>
            <design-reply-form
              v-if="isAnnotating"
              ref="newDiscussionForm"
              :design-note-mutation="$options.createImageDiffNoteMutation"
              :mutation-variables="mutationVariables"
              :markdown-preview-path="markdownPreviewPath"
              :noteable-id="design.id"
              :is-discussion="true"
              @note-submit-complete="addImageDiffNoteToStore"
              @cancel-form="closeCommentForm"
            />
          </template>
        </design-sidebar>
      </div>
    </div>
  </div>
</template>
