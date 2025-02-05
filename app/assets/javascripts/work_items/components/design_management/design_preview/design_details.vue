<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlAlert } from '@gitlab/ui';
import { isNull } from 'lodash';
import { createAlert } from '~/alert';
import { Mousetrap } from '~/lib/mousetrap';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { keysFor, ISSUE_CLOSE_DESIGN } from '~/behaviors/shortcuts/keybindings';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { ROUTES } from '../../../constants';
import getDesignQuery from '../graphql/design_details.query.graphql';
import getWorkItemDesignListQuery from '../graphql/design_collection.query.graphql';
import createImageDiffNoteMutation from '../graphql/create_image_diff_note.mutation.graphql';
import repositionImageDiffNoteMutation from '../graphql/reposition_image_diff_note.mutation.graphql';
import archiveDesignMutation from '../graphql/archive_design.mutation.graphql';
import {
  extractDiscussions,
  getPageLayoutElement,
  findVersionId,
  repositionImageDiffNoteOptimisticResponse,
} from '../utils';
import {
  updateStoreAfterDesignsArchive,
  updateWorkItemDesignCurrentTodosWidget,
  updateStoreAfterAddImageDiffNote,
  updateStoreAfterRepositionImageDiffNote,
} from '../cache_updates';
import {
  DESIGN_DETAIL_LAYOUT_CLASSLIST,
  DESIGN_NOT_FOUND_ERROR,
  DESIGN_SINGLE_ARCHIVE_ERROR,
  UPDATE_IMAGE_DIFF_NOTE_ERROR,
  DELETE_NOTE_ERROR,
  DESIGN_VERSION_NOT_EXIST_ERROR,
} from '../constants';
import DesignReplyForm from '../design_notes/design_reply_form.vue';
import DesignPresentation from './design_presentation.vue';
import DesignToolbar from './design_toolbar.vue';
import DesignSidebar from './design_sidebar.vue';
import DesignScaler from './design_scaler.vue';

const DEFAULT_SCALE = 1;
const DEFAULT_MAX_SCALE = 2;

export default {
  components: {
    DesignPresentation,
    DesignSidebar,
    DesignToolbar,
    DesignScaler,
    DesignReplyForm,
    GlAlert,
  },
  inject: ['fullPath'],
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
    iid: {
      type: String,
      required: true,
    },
    allDesigns: {
      type: Array,
      required: false,
      default: () => [],
    },
    allVersions: {
      type: Array,
      required: false,
      default: () => [],
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
      workItemId: '',
      workItemTitle: '',
      isSidebarOpen: true,
    };
  },
  apollo: {
    design: {
      query: getDesignQuery,
      variables() {
        return this.designVariables;
      },
      update(data) {
        const { event, image, imageV432x230 } = data.designManagement.designAtVersion;
        return {
          ...data.designManagement.designAtVersion.design,
          event,
          image,
          imageV432x230,
        };
      },
      result({ data }) {
        if (!data?.designManagement?.designAtVersion?.design) {
          this.onQueryError(DESIGN_NOT_FOUND_ERROR);
        } else if (this.$route.query.version && !this.hasValidVersion) {
          this.onQueryError(DESIGN_VERSION_NOT_EXIST_ERROR);
        }
      },
      error() {
        this.onQueryError(DESIGN_NOT_FOUND_ERROR);
      },
    },
  },
  computed: {
    designId() {
      const design = this.allDesigns.find((d) => d.filename === this.$route.params.id);
      return design?.id;
    },
    isLoading() {
      return this.$apollo.queries.design.loading;
    },
    markdownPreviewPath() {
      return `/${this.fullPath}/-/preview_markdown?target_type=Issue`;
    },
    designVariables() {
      const versionId = getIdFromGraphQLId(
        this.hasValidVersion ? this.designsVersion : this.latestVersionId,
      );
      const designId = getIdFromGraphQLId(this.designId);
      return {
        id: `gid://gitlab/DesignManagement::DesignAtVersion/${designId}.${versionId}`,
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
    hasValidVersion() {
      return this.$route.query.version;
    },
    designsVersion() {
      return this.hasValidVersion
        ? `gid://gitlab/DesignManagement::Version/${this.$route.query.version}`
        : null;
    },
    discussions() {
      if (!this.design.discussions) {
        return [];
      }
      return extractDiscussions(this.design.discussions);
    },
    resolvedDiscussions() {
      return this.discussions.filter((discussion) => discussion.resolved);
    },
    currentUserDesignTodos() {
      return this.design?.currentUserTodos?.nodes;
    },
    designCollectionQueryBody() {
      return {
        query: getWorkItemDesignListQuery,
        variables: { id: this.workItemId, atVersion: null },
      };
    },
    latestVersionId() {
      const latestVersion = this.allVersions[0];
      return latestVersion && findVersionId(latestVersion.id);
    },
    isLatestVersion() {
      if (this.allVersions.length > 0) {
        return (
          !this.hasValidVersion ||
          !this.latestVersionId ||
          this.hasValidVersion === this.latestVersionId
        );
      }
      return true;
    },
    isAnnotating() {
      return Boolean(this.annotationCoordinates);
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
  },
  methods: {
    addImageDiffNoteToStore({ store, data }) {
      const { createImageDiffNote } = data;

      updateStoreAfterAddImageDiffNote(
        store,
        createImageDiffNote,
        getDesignQuery,
        this.designVariables,
      );
      this.closeCommentForm(data);
    },
    async onMoveNote({ noteId, discussionId, position }) {
      const currentDiscussion = this.discussions.find((el) => el.id === discussionId);
      const note = currentDiscussion?.notes.find(
        ({ discussion }) => discussion?.id === discussionId,
      );

      try {
        await this.$apollo.mutate({
          mutation: repositionImageDiffNoteMutation,
          variables: {
            input: {
              id: noteId,
              position,
            },
          },
          optimisticResponse:
            note &&
            repositionImageDiffNoteOptimisticResponse(note, {
              position,
            }),
          update: this.afterDesignMove,
        });
      } catch (error) {
        Sentry.captureException(error);
        this.onQueryError(UPDATE_IMAGE_DIFF_NOTE_ERROR);
        this.errorMessage = UPDATE_IMAGE_DIFF_NOTE_ERROR;
      }
    },
    afterDesignMove(store, { data: { repositionImageDiffNote } }) {
      return updateStoreAfterRepositionImageDiffNote(
        store,
        repositionImageDiffNote,
        getDesignQuery,
        this.designVariables,
      );
    },
    onError(message, e) {
      this.errorMessage = message;
      if (e) throw e;
    },
    onQueryError(message) {
      // because we redirect user to work item page,
      // we want to create these alerts on the work item page
      createAlert({ message });
      this.$router.push({ name: ROUTES.workItem });
    },
    onDeleteNoteError(e) {
      this.onError(DELETE_NOTE_ERROR, e);
    },
    onResolveDiscussionError(e) {
      this.onError(UPDATE_IMAGE_DIFF_NOTE_ERROR, e);
    },
    closeDesign() {
      this.$router.push({
        name: ROUTES.workItem,
        query: this.$route.query,
      });
    },
    setMaxScale(event) {
      this.maxScale = 1 / event;
    },
    toggleSidebar() {
      this.isSidebarOpen = !this.isSidebarOpen;
    },
    toggleResolvedComments(newValue) {
      this.resolvedDiscussionsExpanded = newValue;
    },
    updateWorkItemDesignCurrentTodosWidgetCache({ cache, todos }) {
      updateWorkItemDesignCurrentTodosWidget({
        store: cache,
        todos,
        query: {
          query: getDesignQuery,
          variables: this.designVariables,
        },
      });
    },
    async onArchiveDesign() {
      try {
        await this.$apollo.mutate({
          mutation: archiveDesignMutation,
          variables: {
            filenames: [this.design.filename],
            projectPath: this.fullPath,
            iid: this.iid,
          },
          update: this.afterArchiveDesign,
        });
      } catch (error) {
        this.onQueryError(DESIGN_SINGLE_ARCHIVE_ERROR);
        this.errorMessage = DESIGN_SINGLE_ARCHIVE_ERROR;
      } finally {
        this.closeDesign();
      }
    },
    afterArchiveDesign(store, { data: { designManagementDelete } }) {
      updateStoreAfterDesignsArchive(
        store,
        designManagementDelete,
        this.designCollectionQueryBody,
        [this.design.filename],
      );
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
  },
  createImageDiffNoteMutation,
};
</script>

<template>
  <div
    class="design-detail js-design-detail fixed-top gl-flex gl-w-full gl-flex-col gl-justify-center gl-bg-subtle lg:gl-flex-row"
  >
    <div class="gl-relative gl-flex gl-grow gl-flex-col gl-overflow-hidden">
      <design-toolbar
        :work-item-title="workItemTitle"
        :design="design"
        :design-filename="$route.params.id"
        :is-loading="isLoading"
        :is-sidebar-open="isSidebarOpen"
        :is-latest-version="isLatestVersion"
        :all-designs="allDesigns"
        :current-user-design-todos="currentUserDesignTodos"
        @toggle-sidebar="toggleSidebar"
        @archive-design="onArchiveDesign"
        @todosUpdated="updateWorkItemDesignCurrentTodosWidgetCache"
      />
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
            :is-sidebar-open="isSidebarOpen"
            :is-loading="isLoading"
            :disable-commenting="!isSidebarOpen"
            @openCommentForm="openCommentForm"
            @moveNote="onMoveNote"
            @setMaxScale="setMaxScale"
          />
        </div>
        <div
          class="design-scaler-wrapper gl-absolute gl-mb-6 gl-flex gl-items-center gl-justify-center"
        >
          <design-scaler :max-scale="maxScale" @scale="scale = $event" />
        </div>
        <design-sidebar
          :design="design"
          :design-variables="designVariables"
          :is-loading="isLoading"
          :is-open="isSidebarOpen"
          :markdown-preview-path="markdownPreviewPath"
          :resolved-discussions-expanded="resolvedDiscussionsExpanded"
          :is-comment-form-present="isAnnotating"
          @deleteNoteError="onDeleteNoteError"
          @resolveDiscussionError="onResolveDiscussionError"
          @toggleResolvedComments="toggleResolvedComments"
        >
          <template #reply-form>
            <design-reply-form
              v-if="isAnnotating"
              ref="newDiscussionForm"
              :design-note-mutation="$options.createImageDiffNoteMutation"
              :mutation-variables="mutationVariables"
              :markdown-preview-path="markdownPreviewPath"
              :noteable-id="design.id"
              :iid="iid"
              @note-submit-complete="addImageDiffNoteToStore"
              @cancel-form="closeCommentForm"
            />
          </template>
        </design-sidebar>
      </div>
    </div>
  </div>
</template>
