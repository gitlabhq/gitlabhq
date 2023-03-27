<script>
import { GlCollapsibleListbox, GlIcon, GlButton, GlTooltipDirective } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { updateText } from '~/lib/utils/text_markdown';
import savedRepliesQuery from './saved_replies.query.graphql';

export default {
  apollo: {
    savedReplies: {
      query: savedRepliesQuery,
      update: (r) => r.currentUser?.savedReplies?.nodes,
      skip() {
        return !this.shouldFetchSavedReplies;
      },
    },
  },
  components: {
    GlCollapsibleListbox,
    GlIcon,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    newSavedRepliesPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      shouldFetchSavedReplies: false,
      savedReplies: [],
      savedRepliesSearch: '',
      loadingSavedReplies: false,
    };
  },
  computed: {
    filteredSavedReplies() {
      const savedReplies = this.savedRepliesSearch
        ? fuzzaldrinPlus.filter(this.savedReplies, this.savedRepliesSearch, { key: ['name'] })
        : this.savedReplies;

      return savedReplies.map((r) => ({ value: r.id, text: r.name, content: r.content }));
    },
  },
  methods: {
    fetchSavedReplies() {
      this.shouldFetchSavedReplies = true;
    },
    setSavedRepliesSearch(search) {
      this.savedRepliesSearch = search;
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
};
</script>

<template>
  <gl-collapsible-listbox
    :header-text="__('Insert saved reply')"
    :items="filteredSavedReplies"
    placement="right"
    searchable
    class="saved-replies-dropdown"
    :searching="$apollo.queries.savedReplies.loading"
    @shown="fetchSavedReplies"
    @search="setSavedRepliesSearch"
    @select="onSelect"
  >
    <template #toggle>
      <gl-button
        v-gl-tooltip
        :title="__('Insert saved reply')"
        :aria-label="__('Insert saved reply')"
        category="tertiary"
        class="gl-px-3!"
        data-testid="saved-replies-dropdown-toggle"
        @keydown.prevent
      >
        <gl-icon name="symlink" class="gl-mr-0!" />
        <gl-icon name="chevron-down" />
      </gl-button>
    </template>
    <template #list-item="{ item }">
      <div class="gl-display-flex js-saved-reply-content">
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
          :href="newSavedRepliesPath"
          category="tertiary"
          block
          class="gl-justify-content-start! gl-mt-0! gl-mb-0! gl-px-3!"
          >{{ __('Add a new saved reply') }}</gl-button
        >
      </div>
    </template>
  </gl-collapsible-listbox>
</template>

<style>
.saved-replies-dropdown .gl-new-dropdown-panel {
  width: 350px;
}

.saved-replies-dropdown .gl-new-dropdown-item-check-icon {
  display: none;
}
</style>
