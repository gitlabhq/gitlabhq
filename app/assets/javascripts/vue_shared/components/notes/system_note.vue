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
// eslint-disable-next-line no-restricted-imports
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
const ICON_COLORS = {
  check: 'system-note-icon-success',
  'merge-request-close': 'system-note-icon-danger',
  merge: 'system-note-icon-info',
  'issue-close': 'system-note-icon-info',
  issues: 'system-note-icon-success',
  error: 'system-note-icon-danger',
  'review-warning': 'system-note-icon-warning',
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
    isAllowedIcon() {
      return Object.keys(ICON_COLORS).includes(this.note.system_note_icon_name);
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
    singleLineDescription() {
      return !this.descriptionVersion?.match(/\n/g);
    },
    deleteButtonClasses() {
      return this.singleLineDescription ? 'gl-top-5 gl-right-2 gl-mt-2' : 'gl-top-6 gl-right-3';
    },
    isMergeRequest() {
      return this.getNoteableData.noteableType === 'MergeRequest';
    },
    iconBgClass() {
      return ICON_COLORS[this.note.system_note_icon_name] || 'gl-bg-strong gl-text-subtle';
    },
    systemNoteIconName() {
      let icon = this.note.system_note_icon_name;
      if (this.note.system_note_icon_name === 'issues') {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        if (this.note.noteable_type === 'Issue') {
          icon = 'issue-open-m';
        } else if (this.note.noteable_type === 'MergeRequest') {
          icon = 'merge-request';
        }
      }
      return icon;
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
    :class="{
      target: isTargetNote,
      'pr-0': shouldShowDescriptionVersion,
    }"
    class="system-note"
  >
    <div
      :class="[
        iconBgClass,
        {
          'system-note-icon -gl-mt-1 gl-ml-2 gl-h-6 gl-w-6': isAllowedIcon,
          'system-note-dot -gl-top-1 gl-ml-4 gl-mt-3 gl-h-3 gl-w-3 gl-border-2 gl-border-solid gl-border-subtle gl-bg-gray-900':
            !isAllowedIcon,
        },
      ]"
      class="gl-relative gl-float-left gl-flex gl-items-center gl-justify-center gl-rounded-full"
    >
      <gl-icon
        v-if="isAllowedIcon"
        :name="systemNoteIconName"
        :size="14"
        data-testid="timeline-icon"
      />
    </div>
    <div class="gl-ml-7">
      <div class="gl-flex gl-items-start gl-justify-between">
        <note-header
          :author="note.author"
          :created-at="note.created_at"
          :note-id="note.id"
          :is-system-note="true"
          :is-imported="note.imported"
        >
          <span ref="gfm-content" v-safe-html="actionTextHtml"></span>
          <template
            v-if="canSeeDescriptionVersion || note.outdated_line_change_path"
            #extra-controls
          >
            <gl-button
              v-if="canSeeDescriptionVersion"
              variant="link"
              :icon="descriptionVersionToggleIcon"
              data-testid="compare-btn"
              class="gl-ml-3 gl-align-text-bottom !gl-text-sm"
              @click="toggleDescriptionVersion"
              >{{ __('Compare with previous version') }}</gl-button
            >
            <gl-button
              v-if="note.outdated_line_change_path"
              :icon="showLines ? 'chevron-up' : 'chevron-down'"
              variant="link"
              data-testid="outdated-lines-change-btn"
              class="gl-align-text-bottom !gl-text-sm"
              @click="toggleDiff"
            >
              {{ __('Compare changes') }}
            </gl-button>
          </template>
        </note-header>
      </div>
      <div class="note-body gl-pb-3 gl-pl-3">
        <div
          v-safe-html="note.note_html"
          :class="{
            'gl-block gl-overflow-hidden': hasMoreCommits,
            'system-note-commit-list': hasMoreCommits && !expanded,
          }"
          class="note-text md"
        ></div>
        <div v-if="hasMoreCommits" class="flex-list">
          <div
            class="flex-row gl-relative gl-z-2 gl-cursor-pointer gl-pl-4 gl-pt-3 gl-text-link hover:gl-underline"
            @click="expanded = !expanded"
          >
            <gl-icon :name="toggleIcon" :size="12" class="gl-mr-2" />
            <span>{{ __('Toggle commit list') }}</span>
          </div>
        </div>
        <div
          v-if="shouldShowDescriptionVersion"
          class="gl-relative !gl-pt-3"
          data-testid="description-version"
        >
          <pre v-if="isLoadingDescriptionVersion" class="loading-state">
            <gl-skeleton-loader />
          </pre>
          <pre
            v-else
            v-safe-html="descriptionVersion"
            class="gl-mt-3 gl-whitespace-pre-wrap gl-pr-7"
          ></pre>
          <gl-button
            v-if="displayDeleteButton"
            v-gl-tooltip
            :title="$options.i18n.deleteButtonLabel"
            :aria-label="$options.i18n.deleteButtonLabel"
            variant="default"
            category="tertiary"
            icon="remove"
            class="gl-absolute"
            :class="deleteButtonClasses"
            data-testid="delete-description-version-button"
            @click="deleteDescriptionVersion"
          />
        </div>
        <div
          v-if="lines.length && showLines"
          class="gl-my-2 gl-mr-5 gl-overflow-hidden gl-overflow-visible gl-rounded-small gl-border-1 gl-border-solid gl-border-strong gl-pl-0"
        >
          <table
            :class="$options.userColorSchemeClass"
            class="code js-syntax-highlight"
            data-testid="outdated-lines"
          >
            <tr v-for="line in lines" v-once :key="line.line_code" class="line_holder">
              <td
                :class="line.type"
                class="diff-line-num old_line !gl-rounded-none !gl-border-0 !gl-border-b-0 !gl-border-t-0"
              >
                {{ line.old_line }}
              </td>
              <td :class="line.type" class="diff-line-num new_line !gl-border-b-0 !gl-border-t-0">
                {{ line.new_line }}
              </td>
              <td
                :class="line.type"
                class="line_content !gl-table-cell !gl-rounded-none !gl-border-0"
                v-html="line.rich_text /* eslint-disable-line vue/no-v-html */"
              ></td>
            </tr>
          </table>
        </div>
        <div v-else-if="showLines" class="gl-mt-4">
          <gl-skeleton-loader />
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
