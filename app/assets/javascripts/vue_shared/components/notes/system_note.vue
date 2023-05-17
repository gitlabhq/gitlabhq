<script>
/**
 * Common component to render a system note, icon and user information.
 *
 * This component needs to be used with a vuex store.
 * That vuex store needs to have a `targetNoteHash` getter
 *
 * @example
 * <system-note
 *   :note="{
 *     id: String,
 *     author: Object,
 *     createdAt: String,
 *     note_html: String,
 *     system_note_icon_name: String
 *    }"
 *   />
 */
import { GlButton, GlSkeletonLoader, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import $ from 'jquery';
import { mapGetters, mapActions, mapState } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import descriptionVersionHistoryMixin from 'ee_else_ce/notes/mixins/description_version_history';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import NoteHeader from '~/notes/components/note_header.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import TimelineEntryItem from './timeline_entry_item.vue';

const MAX_VISIBLE_COMMIT_LIST_COUNT = 3;
const MR_ICON_COLORS = {
  check: 'gl-bg-green-100 gl-text-green-700',
  'merge-request-close': 'gl-bg-red-100 gl-text-red-700',
  merge: 'gl-bg-blue-100 gl-text-blue-700',
};
const ICON_COLORS = {
  'issue-close': 'gl-bg-blue-100 gl-text-blue-700',
};

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
    };
  },
  computed: {
    ...mapGetters(['targetNoteHash', 'descriptionVersions', 'getNoteableData']),
    ...mapState(['isLoadingDescriptionVersion']),
    noteAnchorId() {
      return `note_${this.note.id}`;
    },
    isTargetNote() {
      return this.targetNoteHash === this.noteAnchorId;
    },
    toggleIcon() {
      return this.expanded ? 'chevron-up' : 'chevron-down';
    },
    // following 2 methods taken from code in `collapseLongCommitList` of notes.js:
    actionTextHtml() {
      return $(this.note.note_html).unwrap().html();
    },
    hasMoreCommits() {
      return $(this.note.note_html).filter('ul').children().length > MAX_VISIBLE_COMMIT_LIST_COUNT;
    },
    descriptionVersion() {
      return this.descriptionVersions[this.note.description_version_id];
    },
    isMergeRequest() {
      return this.getNoteableData.noteableType === 'MergeRequest';
    },
    hasIconColors() {
      if (!this.isMergeRequest) return true;

      return this.isMergeRequest && MR_ICON_COLORS[this.note.system_note_icon_name];
    },
    iconBgClass() {
      const colors = this.isMergeRequest ? MR_ICON_COLORS : ICON_COLORS;

      return colors[this.note.system_note_icon_name] || 'gl-bg-gray-50 gl-text-gray-600';
    },
  },
  mounted() {
    renderGFM(this.$refs['gfm-content']);
  },
  methods: {
    ...mapActions(['fetchDescriptionVersion', 'softDeleteDescriptionVersion']),
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
      :class="[
        iconBgClass,
        {
          'mr-system-note-empty gl-bg-gray-900!': !hasIconColors,
          'gl-w-6 gl-h-6 gl-mt-n1 gl-ml-2': !isMergeRequest,
          'mr-system-note-icon': isMergeRequest,
        },
      ]"
      class="gl-float-left gl--flex-center gl-rounded-full gl-relative timeline-icon"
    >
      <gl-icon
        v-if="note.system_note_icon_name && hasIconColors"
        :name="note.system_note_icon_name"
        :size="isMergeRequest ? 12 : 16"
        data-testid="timeline-icon"
      />
    </div>
    <div class="timeline-content">
      <div class="note-header">
        <note-header
          :author="note.author"
          :created-at="note.created_at"
          :note-id="note.id"
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
          v-safe-html="note.note_html"
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
