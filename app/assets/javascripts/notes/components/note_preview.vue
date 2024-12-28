<script>
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_NOTE } from '~/graphql_shared/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import SafeHtml from '~/vue_shared/directives/safe_html';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import noteQuery from '../graphql/note.query.graphql';
import NoteEditedText from './note_edited_text.vue';
import NoteableNote from './noteable_note.vue';

export default {
  components: {
    NoteEditedText,
    NoteableNote,
  },
  directives: {
    SafeHtml,
  },
  mixins: [timeagoMixin],
  props: {
    noteId: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      note: null,
      hidden: false,
    };
  },
  computed: {
    showNote() {
      return this.note && !this.hidden && !this.isSyntheticNote;
    },
    showEdited() {
      return this.note && this.note.created_at !== this.note.last_edited_at;
    },
    isSyntheticNote() {
      return Boolean(this.noteId?.match(/([a-f0-9]{40})/));
    },
    noteHtml() {
      return this.note?.body_html;
    },
  },
  watch: {
    async noteHtml() {
      try {
        await this.$nextTick();
        renderGFM(this.$refs.noteBody);
      } catch {
        this.fallback();
      }
    },
  },
  mounted() {
    if (this.isSyntheticNote) {
      this.fallback();
    }
  },
  methods: {
    fallback() {
      this.hidden = true;
    },
  },
  apollo: {
    note: {
      skip() {
        return !this.noteId || this.isSyntheticNote;
      },
      query: noteQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_NOTE, this.noteId),
        };
      },
      update(data) {
        if (!data?.note) return null;
        return {
          ...data.note,
          author: {
            ...data.note.author,
            id: getIdFromGraphQLId(data.note.author.id),
          },
          last_edited_by: {
            ...data.note.last_edited_by,
            id: getIdFromGraphQLId(data.note.last_edited_by?.id),
          },
          id: getIdFromGraphQLId(data.note.id),
        };
      },
      result(result) {
        if (result?.errors?.length > 0) {
          Sentry.captureException(result.errors[0].message);
          this.fallback();
        }

        if (!result?.data?.note) {
          this.fallback();
        }
      },
      error(error) {
        Sentry.captureException(error);
        this.fallback();
      },
    },
  },
};
</script>

<template>
  <noteable-note
    v-if="showNote"
    :id="`note_${noteId}`"
    :note="note"
    :show-reply-button="false"
    should-scroll-to-note
  >
    <template #note-body>
      <div ref="noteBody" class="note-body">
        <div v-safe-html:[$options.safeHtmlConfig]="noteHtml" class="note-text md"></div>
        <note-edited-text
          v-if="showEdited"
          :edited-at="note.last_edited_at"
          :edited-by="note.last_edited_by"
          :action-text="__('Edited')"
          class="note_edited_ago"
        />
      </div>
    </template>
  </noteable-note>
</template>
