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
  'issue-close': 'gl-bg-blue-100! gl-text-blue-700',
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
    :class="{ target: isTargetNote, 'pr-0': shouldShowDescriptionVersion }"
    class="note system-note note-wrapper"
  >
    <div
      :class="[
        getIconColor,
        {
          'gl-bg-gray-50 gl-text-gray-600 system-note-icon': isAllowedIcon,
          'system-note-tiny-dot gl-bg-gray-900!': !isAllowedIcon,
        },
      ]"
      class="gl-float-left gl-flex gl-justify-center gl-items-center gl-rounded-full gl-relative"
    >
      <gl-icon v-if="isAllowedIcon" :size="12" :name="note.systemNoteIconName" />
    </div>
    <div class="timeline-content">
      <div class="note-header">
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
              class="gl-vertical-align-text-bottom gl-font-sm!"
              @click="toggleDescriptionVersion"
              >{{ __('Compare with previous version') }}</gl-button
            >
          </template>
        </note-header>
      </div>
      <div class="note-body">
        <div v-if="shouldShowDescriptionVersion" class="description-version gl-pt-3! gl-pl-4">
          <pre v-if="isLoadingDescriptionVersion" class="loading-state">
            <gl-skeleton-loader />
          </pre>
          <pre
            v-else
            v-safe-html="descriptionVersion"
            data-testid="description-version-diff"
            class="wrapper gl-mt-3"
          ></pre>
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
      </div>
    </div>
  </timeline-entry-item>
</template>
