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
import descriptionVersionHistoryMixin from 'ee_else_ce/work_items/mixins/description_version_history';
import { getLocationHash } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import NoteHeader from '~/notes/components/note_header.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

const ALLOWED_ICONS = ['issue-close'];
const ICON_COLORS = {
  'issue-close': '!gl-bg-blue-100 gl-text-blue-700 icon-info',
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
  mixins: [descriptionVersionHistoryMixin],
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
      descriptionVersions: {},
    };
  },
  computed: {
    targetNoteHash() {
      return getLocationHash();
    },
    noteAnchorId() {
      return `note_${this.noteId}`;
    },
    getIconColor() {
      return ICON_COLORS[this.note.systemNoteIconName] || '';
    },
    isAllowedIcon() {
      return ALLOWED_ICONS.includes(this.note.systemNoteIconName);
    },
    isTargetNote() {
      return this.targetNoteHash === this.noteAnchorId;
    },
    toggleIcon() {
      return this.expanded ? 'chevron-up' : 'chevron-down';
    },
    actionTextHtml() {
      return $(this.note.bodyHtml).unwrap().html();
    },
    descriptionVersionId() {
      return getIdFromGraphQLId(this.systemNoteDescriptionVersion?.id);
    },
    noteId() {
      return getIdFromGraphQLId(this.note.id);
    },
    descriptionVersion() {
      return this.descriptionVersions[this.descriptionVersionId];
    },
    singleLineDescription() {
      return !this.descriptionVersion?.match(/\n/g);
    },
    deleteButtonClasses() {
      return this.singleLineDescription ? 'gl-top-5 gl-right-2 gl-mt-2' : 'gl-top-6 gl-right-3';
    },
  },
  mounted() {
    renderGFM(this.$refs['gfm-content']);
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
    :class="{
      target: isTargetNote,
      'pr-0': shouldShowDescriptionVersion,
    }"
    class="system-note"
  >
    <div
      :class="[
        getIconColor,
        {
          'system-note-icon -gl-mt-1 gl-ml-2 gl-h-6 gl-w-6': isAllowedIcon,
          'system-note-dot -gl-top-1 gl-ml-4 gl-mt-3 gl-h-3 gl-w-3 gl-border-2 gl-border-solid gl-border-subtle gl-bg-gray-900':
            !isAllowedIcon,
        },
      ]"
      class="gl-relative gl-float-left gl-flex gl-items-center gl-justify-center gl-rounded-full"
    >
      <gl-icon v-if="isAllowedIcon" :size="14" :name="note.systemNoteIconName" />
    </div>
    <div class="gl-ml-7">
      <div class="gl-flex gl-items-start gl-justify-between">
        <note-header
          :author="note.author"
          :created-at="note.createdAt"
          :note-id="noteId"
          :is-system-note="true"
        >
          <span ref="gfm-content" v-safe-html="actionTextHtml" class="gl-break-anywhere"></span>
          <template v-if="canSeeDescriptionVersion" #extra-controls>
            &middot;
            <gl-button
              v-if="canSeeDescriptionVersion"
              variant="link"
              :icon="descriptionVersionToggleIcon"
              data-testid="compare-btn"
              class="gl-align-text-bottom !gl-text-sm"
              @click="toggleDescriptionVersion"
              >{{ __('Compare with previous version') }}</gl-button
            >
          </template>
        </note-header>
      </div>
      <div class="note-body gl-pb-3 gl-pl-3">
        <div v-if="shouldShowDescriptionVersion" class="gl-relative !gl-pt-3">
          <pre v-if="isLoadingDescriptionVersion" class="loading-state">
            <gl-skeleton-loader />
          </pre>
          <pre
            v-else
            v-safe-html="descriptionVersion"
            data-testid="description-version-diff"
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
      </div>
    </div>
  </timeline-entry-item>
</template>
