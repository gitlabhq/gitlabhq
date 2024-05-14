<script>
import { GlCollapsibleListbox, GlTooltip, GlButton } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { getDerivedMergeRequestInformation } from '~/diffs/utils/merge_request';
import { InternalEvents } from '~/tracking';
import savedRepliesQuery from 'ee_else_ce/vue_shared/components/markdown/saved_replies.query.graphql';
import {
  TRACKING_SAVED_REPLIES_USE,
  TRACKING_SAVED_REPLIES_USE_IN_MR,
  TRACKING_SAVED_REPLIES_USE_IN_OTHER,
  COMMENT_TEMPLATES_KEYS,
  COMMENT_TEMPLATES_TITLES,
} from 'ee_else_ce/vue_shared/components/markdown/constants';

export default {
  apollo: {
    savedReplies: {
      query: savedRepliesQuery,
      manual: true,
      result({ data, loading }) {
        if (!loading) {
          this.savedReplies = data;
        }
      },
      variables() {
        const groupPath = document.body.dataset.groupFullPath;
        const projectPath = document.body.dataset.projectFullPath;

        return {
          groupPath,
          hideGroup: !groupPath,
          projectPath,
          hideProject: !projectPath,
        };
      },
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
  mixins: [InternalEvents.mixin()],
  props: {
    newCommentTemplatePaths: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      shouldFetchCommentTemplates: false,
      savedReplies: {},
      commentTemplateSearch: '',
      loadingSavedReplies: false,
    };
  },
  computed: {
    allSavedReplies() {
      return COMMENT_TEMPLATES_KEYS.map((key) => ({
        text: COMMENT_TEMPLATES_TITLES[key],
        options: (this.savedReplies[key]?.savedReplies?.nodes || []).map((r) => ({
          value: r.id,
          text: r.name,
          content: r.content,
        })),
      }));
    },
    filteredSavedReplies() {
      let savedReplies = this.allSavedReplies;

      if (this.commentTemplateSearch) {
        savedReplies = savedReplies
          .map((group) => ({
            ...group,
            options: fuzzaldrinPlus.filter(group.options, this.commentTemplateSearch, {
              key: ['text'],
            }),
          }))
          .filter(({ options }) => options.length);
      }

      return savedReplies.filter(({ options }) => options.length);
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
      let savedReply;
      const isInMr = Boolean(getDerivedMergeRequestInformation({ endpoint: window.location }).id);

      for (let i = 0, len = this.allSavedReplies.length; i < len; i += 1) {
        const { options } = this.allSavedReplies[i];
        savedReply = options.find(({ value }) => value === id);

        if (savedReply) break;
      }

      if (savedReply) {
        this.$emit('select', savedReply.content);
        this.trackEvent(TRACKING_SAVED_REPLIES_USE);
        this.trackEvent(
          isInMr ? TRACKING_SAVED_REPLIES_USE_IN_MR : TRACKING_SAVED_REPLIES_USE_IN_OTHER,
        );
      }
    },
  },
};
</script>

<template>
  <span>
    <gl-collapsible-listbox
      :header-text="__('Insert comment template')"
      :items="filteredSavedReplies"
      :toggle-text="__('Insert comment template')"
      text-sr-only
      no-caret
      toggle-class="js-comment-template-toggle"
      icon="comment-lines"
      category="tertiary"
      placement="right"
      searchable
      size="small"
      class="comment-template-dropdown gl-mr-2"
      positioning-strategy="fixed"
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
          class="gl-border-t-solid gl-border-t-1 gl-border-t-gray-200 gl-display-flex gl-justify-content-center gl-flex-direction-column gl-p-2"
        >
          <gl-button
            v-for="(manage, index) in newCommentTemplatePaths"
            :key="index"
            :href="manage.path"
            category="tertiary"
            block
            class="gl-justify-content-start! gl-mt-0! gl-mb-0! gl-px-3!"
            data-testid="manage-button"
            >{{ manage.text }}</gl-button
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
  width: 350px !important;
}

.comment-template-dropdown .gl-new-dropdown-item-check-icon {
  display: none;
}

.comment-template-dropdown input {
  border-radius: 0;
}
</style>
