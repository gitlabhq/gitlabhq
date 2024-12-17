<script>
import { GlAvatar, GlPopover, GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_NOTE } from '~/graphql_shared/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import noteQuery from '../queries/note.query.graphql';
import { renderGFM } from '../../../behaviors/markdown/render_gfm';

export default {
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
  components: {
    GlAvatar,
    GlPopover,
    GlSkeletonLoader,
    GlSprintf,
  },
  directives: {
    SafeHtml,
  },
  mixins: [timeagoMixin],
  props: {
    target: {
      type: HTMLAnchorElement,
      required: true,
    },
  },
  apollo: {
    note: {
      skip() {
        return !this.noteId;
      },
      query: noteQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_NOTE, this.noteId),
        };
      },
      result(result) {
        if (result?.errors?.length > 0) {
          this.fallback();
          return null;
        }

        if (!result?.data?.note) {
          this.fallback();
          return null;
        }

        return result.data.note;
      },
      error() {
        this.fallback();
      },
    },
  },
  data() {
    return {
      note: null,
      show: true,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.note?.loading;
    },
    urlHash() {
      return this.target.href.split('#')[1] || '';
    },
    noteId() {
      const [, noteId] = this.urlHash.match(/note_([0-9]+)/) || [];
      return noteId || '';
    },
    author() {
      return this.note?.author;
    },
    noteCreatedAt() {
      return this.timeFormatted(this.note?.createdAt);
    },
    noteText() {
      // for empty line (if it's an image or other non-text content)
      if (this.note?.bodyFirstLineHtml === '<p></p>') {
        return '';
      }
      return this.note?.bodyFirstLineHtml;
    },
  },
  methods: {
    renderGFM() {
      renderGFM(this.$refs.gfm);
    },
    fallback() {
      this.show = false;
    },
  },
  cssClasses: ['gl-max-w-48', 'gl-overflow-hidden'],
};
</script>

<template>
  <gl-popover :target="target" boundary="viewport" :css-classes="$options.cssClasses" :show="show">
    <gl-skeleton-loader v-if="loading" :lines="2" :height="24" equal-width-lines />
    <div v-if="author" class="gl-flex gl-gap-2 gl-text-subtle">
      <gl-avatar :src="author.avatarUrl" :size="16" />
      <div>
        <gl-sprintf :message="__('%{author} commented %{time}')">
          <template #author>
            <span class="gl-break-all gl-text-sm">{{ author.name }}</span>
          </template>
          <template #time>
            <span class="gl-text-sm">{{ noteCreatedAt }}</span>
          </template>
        </gl-sprintf>
      </div>
    </div>
    <div
      v-if="noteText"
      ref="gfmContent"
      v-safe-html:[$options.safeHtmlConfig]="noteText"
      class="md gl-mt-2"
    ></div>
  </gl-popover>
</template>
