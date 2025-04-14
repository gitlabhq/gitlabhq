<script>
import { GlAlert } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import { produce } from 'immer';
import { __ } from '~/locale';
import wikiPageQuery from '~/wikis/graphql/wiki_page.query.graphql';
import SkeletonNote from '~/vue_shared/components/notes/skeleton_note.vue';
import eventHub, { EVENT_EDIT_WIKI_DONE, EVENT_EDIT_WIKI_START } from '../../event_hub';
import OrderedLayout from './ordered_layout.vue';
import PlaceholderNote from './placeholder_note.vue';
import WikiNotesActivityHeader from './wiki_notes_activity_header.vue';
import WikiCommentForm from './wiki_comment_form.vue';
import WikiDiscussion from './wiki_discussion.vue';

export default {
  i18n: {
    loadingFailedErrText: __(
      'Something went wrong while fetching comments. Please refresh the page.',
    ),
    retryText: __('Retry'),
  },
  name: 'WikiNotesApp',
  components: {
    GlAlert,
    WikiCommentForm,
    WikiDiscussion,
    WikiNotesActivityHeader,
    OrderedLayout,
    SkeletonNote,
    PlaceholderNote,
  },
  inject: ['containerId', 'noteCount', 'queryVariables'],
  apollo: {
    wikiPage: {
      query: wikiPageQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.wikiPage?.discussions?.nodes || [];
      },
      error() {
        this.loadingFailed = true;
        return [];
      },
      result({ data }) {
        this.noteableId = data?.wikiPage?.id || '';
        this.discussions = cloneDeep(data?.wikiPage?.discussions?.nodes) || [];
      },
    },
  },
  data() {
    return {
      wikiPage: {},
      noteableId: '',
      loadingFailed: false,
      placeholderNote: {},
      slotKeys: ['comments', 'place-holder-note', 'form'],
      discussions: Array.from({ length: this.noteCount }, (_, index) => ({
        id: index,
        isSkeletonNote: true,
      })),
      isEditingPage: false,
    };
  },
  computed: {
    wikiPageData() {
      return this.$apollo.queries.wikiPage;
    },
    isLoading() {
      return this.$apollo.queries.wikiPage.loading;
    },
    queryData() {
      const { defaultClient: cache } = this.$apollo.provider.clients;

      return cache.readQuery({
        query: wikiPageQuery,
        variables: this.queryVariables,
      });
    },
  },
  mounted() {
    eventHub.$on(EVENT_EDIT_WIKI_START, () => {
      this.isEditingPage = true;
    });

    eventHub.$on(EVENT_EDIT_WIKI_DONE, () => {
      this.isEditingPage = false;
    });
  },
  methods: {
    setPlaceHolderNote(note) {
      this.placeholderNote = note;
    },
    removePlaceholder() {
      this.placeholderNote = {};
    },
    getDiscussionKey(key, stringModifier) {
      return [key, stringModifier].join('-');
    },
    handleDeleteNote(noteId, discussionId) {
      const discussionIndex = this.discussions.findIndex(
        (discussion) => discussion.id === discussionId,
      );

      if (discussionIndex === -1) return;

      const discussion = this.discussions[discussionIndex];
      const isLastNote = discussion.notes.nodes.length === 1;

      // Update local state
      if (isLastNote) {
        // Remove entire discussion if it's the last note
        this.discussions = this.discussions.filter(({ id }) => id !== discussionId);
      } else {
        // Remove only the specific note
        this.discussions[discussionIndex].notes.nodes = discussion.notes.nodes.filter(
          ({ id }) => id !== noteId,
        );
      }

      this.updateCache({ discussionId, noteId, isLastNote });
    },

    updateCache({ discussion, discussionId, noteId, isLastNote }) {
      if (!this.$apollo.provider) return;
      const { defaultClient: cache } = this.$apollo.provider.clients;

      const queryData = cache.readQuery({
        query: wikiPageQuery,
        variables: this.queryVariables,
      });

      if (!queryData) return;

      let data;
      if (discussion) {
        data = produce(queryData, (draft) => {
          draft.wikiPage.discussions.nodes.push({
            ...discussion,
            replyId: null,
            resolvable: false,
            resolved: false,
            resolvedAt: null,
            resolvedBy: null,
          });
        });
      } else {
        data = produce(queryData, (draft) => {
          const cachedDiscussionIndex = draft.wikiPage.discussions.nodes.findIndex(
            (d) => d.id === discussionId,
          );

          if (cachedDiscussionIndex === -1) return;

          if (isLastNote) {
            // Remove entire discussion if it's the last note
            draft.wikiPage.discussions.nodes = draft.wikiPage.discussions.nodes.filter(
              (d) => d.id !== discussionId,
            );
          } else {
            // Remove only the specific note
            draft.wikiPage.discussions.nodes[cachedDiscussionIndex].notes.nodes =
              draft.wikiPage.discussions.nodes[cachedDiscussionIndex].notes.nodes.filter(
                (note) => note.id !== noteId,
              );
          }
        });
      }

      cache.writeQuery({
        query: wikiPageQuery,
        variables: this.queryVariables,
        data,
      });
    },
  },
};
</script>
<template>
  <div v-if="!isEditingPage">
    <wiki-notes-activity-header />
    <ordered-layout :slot-keys="slotKeys">
      <template #form>
        <wiki-comment-form
          v-if="!isLoading"
          :noteable-id="noteableId"
          :note-id="noteableId"
          @creating-note:start="setPlaceHolderNote"
          @creating-note:done="removePlaceholder"
          @creating-note:success="(discussion) => updateCache({ discussion })"
        />
      </template>
      <template v-if="placeholderNote.body" #place-holder-note>
        <ul class="notes main-notes-list timeline">
          <placeholder-note :note="placeholderNote" />
        </ul>
      </template>
      <template #comments>
        <gl-alert
          v-if="loadingFailed"
          :dismissible="false"
          variant="danger"
          :primary-button-text="$options.i18n.retryText"
          @primaryAction="wikiPageData.refetch()"
        >
          {{ $options.i18n.loadingFailedErrText }}
        </gl-alert>
        <ul v-else id="notes-list" class="notes main-notes-list timeline">
          <template v-for="discussion in discussions">
            <skeleton-note
              v-if="discussion.isSkeletonNote"
              :key="getDiscussionKey(discussion.id, 'skeleton')"
              class="note-skeleton"
            />
            <wiki-discussion
              v-else
              :key="getDiscussionKey(discussion.id, 'discussion')"
              :noteable-id="noteableId"
              :discussion="discussion.notes.nodes"
              @note-deleted="(noteId) => handleDeleteNote(noteId, discussion.id)"
            />
          </template>
        </ul>
      </template>
    </ordered-layout>
  </div>
</template>
