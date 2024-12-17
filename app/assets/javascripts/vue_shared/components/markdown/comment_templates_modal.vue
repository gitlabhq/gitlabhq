<script>
import {
  GlTooltipDirective,
  GlButton,
  GlModal,
  GlSearchBoxByType,
  GlTruncate,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { uniqueId } from 'lodash';
import modalKeyboardNavigationMixin from '~/vue_shared/mixins/modal_keyboard_navigation_mixin';
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
    GlButton,
    GlModal,
    GlSearchBoxByType,
    GlTruncate,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin(), modalKeyboardNavigationMixin],
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
        name: COMMENT_TEMPLATES_TITLES[key],
        items: (this.savedReplies[key]?.savedReplies?.nodes || []).map((r) => ({
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
            items: fuzzaldrinPlus.filter(group.items, this.commentTemplateSearch, {
              key: ['text'],
            }),
          }))
          .filter(({ items }) => items.length);
      }

      return savedReplies.filter(({ items }) => items.length);
    },
    modalId() {
      return uniqueId('insert-comment-template-modal-');
    },
  },
  methods: {
    onSelect(savedReply) {
      const isInMr = Boolean(getDerivedMergeRequestInformation({ endpoint: window.location }).id);

      this.$emit('select', savedReply.content);
      this.trackEvent(TRACKING_SAVED_REPLIES_USE);
      this.trackEvent(
        isInMr ? TRACKING_SAVED_REPLIES_USE_IN_MR : TRACKING_SAVED_REPLIES_USE_IN_OTHER,
      );
      this.shouldFetchCommentTemplates = false;
    },
    toggleModal() {
      this.shouldFetchCommentTemplates = !this.shouldFetchCommentTemplates;
    },
  },
};
</script>

<template>
  <span>
    <gl-modal
      ref="modal"
      v-model="shouldFetchCommentTemplates"
      :title="__('Select a comment template')"
      scrollable
      :modal-id="modalId"
      modal-class="comment-templates-modal"
    >
      <gl-search-box-by-type
        ref="searchInput"
        v-model="commentTemplateSearch"
        :placeholder="__('Search comment templates')"
        @keydown="onKeydown"
      />
      <section v-if="!filteredSavedReplies.length" class="gl-mt-3">
        {{ __('No comment templates found.') }}
      </section>
      <ul
        v-else
        ref="resultsList"
        class="comment-templates-options gl-m-0 gl-list-none gl-p-0"
        data-testid="comment-templates-list"
        @keydown="onKeydown"
      >
        <gl-disclosure-dropdown-group
          v-for="(commentTemplateGroup, index) in filteredSavedReplies"
          :key="commentTemplateGroup.name"
          :class="{ '!gl-mt-0 !gl-border-t-0 gl-pt-0': index === 0 }"
          :group="commentTemplateGroup"
          bordered
          @action="onSelect"
        >
          <template #list-item="{ item }">
            <strong class="gl-block gl-w-full">{{ item.text }}</strong>
            <gl-truncate class="gl-mt-2 gl-text-subtle" :text="item.content" position="end" />
          </template>
        </gl-disclosure-dropdown-group>
      </ul>
      <template #modal-footer>
        <gl-disclosure-dropdown
          :items="newCommentTemplatePaths"
          :toggle-text="__('Manage comment templates')"
          placement="bottom-end"
          fluid-width
          data-testid="manage-dropdown"
        >
          <template #header>
            <div
              class="gl-min-h-8 gl-border-b-1 gl-border-b-dropdown !gl-p-4 gl-text-sm gl-font-bold gl-border-b-solid"
            >
              {{ __('Manage') }}
            </div>
          </template>
        </gl-disclosure-dropdown>
      </template>
    </gl-modal>
    <gl-button
      v-gl-tooltip
      :title="__('Insert comment template')"
      :aria-label="__('Insert comment template')"
      category="tertiary"
      size="small"
      icon="comment-lines"
      class="js-comment-template-toggle"
      data-testid="comment-templates-dropdown-toggle"
      @click="toggleModal"
    />
  </span>
</template>
