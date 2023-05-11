<script>
import { GlCollapsibleListbox, GlTooltip, GlButton } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { updateText } from '~/lib/utils/text_markdown';
import savedRepliesQuery from './saved_replies.query.graphql';

export default {
  apollo: {
    savedReplies: {
      query: savedRepliesQuery,
      update: (r) => r.currentUser?.savedReplies?.nodes,
      skip() {
        return !this.shouldFetchCommentTemplates;
      },
    },
  },
  components: {
    GlCollapsibleListbox,
    GlButton,
    GlTooltip,
  },
  props: {
    newCommentTemplatePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      shouldFetchCommentTemplates: false,
      savedReplies: [],
      commentTemplateSearch: '',
      loadingSavedReplies: false,
    };
  },
  computed: {
    filteredSavedReplies() {
      const savedReplies = this.commentTemplateSearch
        ? fuzzaldrinPlus.filter(this.savedReplies, this.commentTemplateSearch, { key: ['name'] })
        : this.savedReplies;

      return savedReplies.map((r) => ({ value: r.id, text: r.name, content: r.content }));
    },
  },
  mounted() {
    this.tooltipTarget = this.$el.querySelector('.js-comment-template-toggle');
  },
  methods: {
    fetchCommentTemplates() {
      this.shouldFetchCommentTemplates = true;
    },
    setCommentTemplateSearch(search) {
      this.commentTemplateSearch = search;
    },
    onSelect(id) {
      const savedReply = this.savedReplies.find((r) => r.id === id);
      const textArea = this.$el.closest('.md-area')?.querySelector('textarea');

      if (savedReply && textArea) {
        updateText({
          textArea,
          tag: savedReply.content,
          cursorOffset: 0,
          wrap: false,
        });

        // Wait for text to be added into textarea
        requestAnimationFrame(() => {
          textArea.focus();
        });
      }
    },
  },
  popperOptions: { strategy: 'fixed' },
};
</script>

<template>
  <span>
    <gl-collapsible-listbox
      :header-text="__('Insert comment template')"
      :items="filteredSavedReplies"
      :toggle-text="__('Insert comment template')"
      text-sr-only
      toggle-class="js-comment-template-toggle"
      icon="comment-lines"
      category="tertiary"
      placement="right"
      searchable
      size="small"
      class="comment-template-dropdown"
      :popper-options="$options.popperOptions"
      :searching="$apollo.queries.savedReplies.loading"
      @shown="fetchCommentTemplates"
      @search="setCommentTemplateSearch"
      @select="onSelect"
    >
      <template #list-item="{ item }">
        <div class="gl-display-flex js-comment-template-content">
          <div class="gl-text-truncate">
            <strong>{{ item.text }}</strong
            ><span class="gl-ml-2">{{ item.content }}</span>
          </div>
        </div>
      </template>
      <template #footer>
        <div
          class="gl-border-t-solid gl-border-t-1 gl-border-t-gray-100 gl-display-flex gl-justify-content-center gl-p-3"
        >
          <gl-button
            :href="newCommentTemplatePath"
            category="tertiary"
            block
            class="gl-justify-content-start! gl-mt-0! gl-mb-0! gl-px-3!"
            >{{ __('Add a new comment template') }}</gl-button
          >
        </div>
      </template>
    </gl-collapsible-listbox>
    <gl-tooltip :target="() => tooltipTarget">
      {{ __('Insert comment template') }}
    </gl-tooltip>
  </span>
</template>

<style>
.comment-template-dropdown .gl-new-dropdown-panel {
  width: 350px;
}

.comment-template-dropdown .gl-new-dropdown-item-check-icon {
  display: none;
}
</style>
