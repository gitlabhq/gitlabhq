<script>
/**
 * Common component to render a system note, icon and user information.
 *
 * This component need not be used with any store neither has any vuex dependency
 *
 * @example
 * <system-note
 *   :note="{
 *     id: String,
 *     author: Object,
 *     createdAt: String,
 *     bodyHtml: String,
 *     systemNoteIconName: String
 *    }"
 *   />
 */
import { GlButton, GlSkeletonLoader, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import $ from 'jquery';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import SafeHtml from '~/vue_shared/directives/safe_html';
import descriptionVersionHistoryMixin from 'ee_else_ce/notes/mixins/description_version_history';
import axios from '~/lib/utils/axios_utils';
import { getLocationHash } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import NoteHeader from '~/notes/components/note_header.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

const MAX_VISIBLE_COMMIT_LIST_COUNT = 3;

export default {
  i18n: {
    deleteButtonLabel: __('Remove description history'),
  },
  name: 'SystemNote',
  components: {
    GlIcon,
    NoteHeader,
    TimelineEntryItem,
    GlButton,
    GlSkeletonLoader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [descriptionVersionHistoryMixin, glFeatureFlagsMixin()],
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      expanded: false,
      lines: [],
      showLines: false,
      loadingDiff: false,
      isLoadingDescriptionVersion: false,
    };
  },
  computed: {
    targetNoteHash() {
      return getLocationHash();
    },
    descriptionVersions() {
      return [];
    },
    noteAnchorId() {
      return `note_${this.noteId}`;
    },
    isTargetNote() {
      return this.targetNoteHash === this.noteAnchorId;
    },
    toggleIcon() {
      return this.expanded ? 'chevron-up' : 'chevron-down';
    },
    // following 2 methods taken from code in `collapseLongCommitList` of notes.js:
    actionTextHtml() {
      return $(this.note.bodyHtml).unwrap().html();
    },
    hasMoreCommits() {
      return $(this.note.bodyHtml).filter('ul').children().length > MAX_VISIBLE_COMMIT_LIST_COUNT;
    },
    descriptionVersion() {
      return this.descriptionVersions[this.note.description_version_id];
    },
    noteId() {
      return getIdFromGraphQLId(this.note.id);
    },
  },
  mounted() {
    renderGFM(this.$refs['gfm-content']);
  },
  methods: {
    fetchDescriptionVersion() {},
    softDeleteDescriptionVersion() {},

    async toggleDiff() {
      this.showLines = !this.showLines;

      if (!this.lines.length) {
        this.loadingDiff = true;
        const { data } = await axios.get(this.note.outdated_line_change_path);

        this.lines = data.map((l) => ({
          ...l,
          rich_text: l.rich_text.replace(/^[+ -]/, ''),
        }));
        this.loadingDiff = false;
      }
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['use'], // to support icon SVGs
  },
  userColorSchemeClass: window.gon.user_color_scheme,
};
</script>

<template>
  <timeline-entry-item
    :id="noteAnchorId"
    :class="{ target: isTargetNote, 'pr-0': shouldShowDescriptionVersion }"
    class="note system-note note-wrapper"
  >
    <div
      class="gl-float-left gl--flex-center gl-rounded-full gl-mt-n1 gl-ml-2 gl-w-6 gl-h-6 gl-bg-gray-50 gl-text-gray-600"
    >
      <gl-icon :name="note.systemNoteIconName" />
    </div>
    <div class="timeline-content">
      <div class="note-header">
        <note-header
          :author="note.author"
          :created-at="note.createdAt"
          :note-id="noteId"
          :is-system-note="true"
        >
          <span ref="gfm-content" v-safe-html="actionTextHtml"></span>
          <template
            v-if="canSeeDescriptionVersion || note.outdated_line_change_path"
            #extra-controls
          >
            &middot;
            <gl-button
              v-if="canSeeDescriptionVersion"
              variant="link"
              :icon="descriptionVersionToggleIcon"
              data-testid="compare-btn"
              class="gl-vertical-align-text-bottom gl-font-sm!"
              @click="toggleDescriptionVersion"
              >{{ __('Compare with previous version') }}</gl-button
            >
            <gl-button
              v-if="note.outdated_line_change_path"
              :icon="showLines ? 'chevron-up' : 'chevron-down'"
              variant="link"
              data-testid="outdated-lines-change-btn"
              class="gl-vertical-align-text-bottom gl-font-sm!"
              @click="toggleDiff"
            >
              {{ __('Compare changes') }}
            </gl-button>
          </template>
        </note-header>
      </div>
      <div class="note-body">
        <div
          v-safe-html="note.bodyHtml"
          :class="{ 'system-note-commit-list': hasMoreCommits, 'hide-shade': expanded }"
          class="note-text md"
        ></div>
        <div v-if="hasMoreCommits" class="flex-list">
          <div class="system-note-commit-list-toggler flex-row" @click="expanded = !expanded">
            <gl-icon :name="toggleIcon" :size="8" class="gl-mr-2" />
            <span>{{ __('Toggle commit list') }}</span>
          </div>
        </div>
        <div v-if="shouldShowDescriptionVersion" class="description-version pt-2">
          <pre v-if="isLoadingDescriptionVersion" class="loading-state">
            <gl-skeleton-loader />
          </pre>
          <pre v-else v-safe-html="descriptionVersion" class="wrapper mt-2"></pre>
          <gl-button
            v-if="displayDeleteButton"
            v-gl-tooltip
            :title="$options.i18n.deleteButtonLabel"
            :aria-label="$options.i18n.deleteButtonLabel"
            variant="default"
            category="tertiary"
            icon="remove"
            class="delete-description-history"
            data-testid="delete-description-version-button"
            @click="deleteDescriptionVersion"
          />
        </div>
        <div
          v-if="lines.length && showLines"
          class="diff-content outdated-lines-wrapper gl-border-solid gl-border-1 gl-border-gray-200 gl-mt-4 gl-rounded-small gl-overflow-hidden"
        >
          <table
            :class="$options.userColorSchemeClass"
            class="code js-syntax-highlight"
            data-testid="outdated-lines"
          >
            <tr v-for="line in lines" v-once :key="line.line_code" class="line_holder">
              <td
                :class="line.type"
                class="diff-line-num old_line gl-border-bottom-0! gl-border-top-0! gl-border-0! gl-rounded-0!"
              >
                {{ line.old_line }}
              </td>
              <td
                :class="line.type"
                class="diff-line-num new_line gl-border-bottom-0! gl-border-top-0!"
              >
                {{ line.new_line }}
              </td>
              <td
                :class="line.type"
                class="line_content gl-display-table-cell! gl-border-0! gl-rounded-0!"
                v-html="line.rich_text /* eslint-disable-line vue/no-v-html */"
              ></td>
            </tr>
          </table>
        </div>
        <div v-else-if="showLines" class="mt-4">
          <gl-skeleton-loader />
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
