<script>
/* eslint-disable vue/no-v-html */

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
import {
  GlButton,
  GlDeprecatedSkeletonLoading as GlSkeletonLoading,
  GlTooltipDirective,
  GlIcon,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import $ from 'jquery';
import { mapGetters, mapActions, mapState } from 'vuex';
import descriptionVersionHistoryMixin from 'ee_else_ce/notes/mixins/description_version_history';
import { __ } from '~/locale';
import initMRPopovers from '~/mr_popover/';
import noteHeader from '~/notes/components/note_header.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { spriteIcon } from '../../../lib/utils/common_utils';
import TimelineEntryItem from './timeline_entry_item.vue';

const MAX_VISIBLE_COMMIT_LIST_COUNT = 3;

export default {
  i18n: {
    deleteButtonLabel: __('Remove description history'),
  },
  name: 'SystemNote',
  components: {
    GlIcon,
    noteHeader,
    TimelineEntryItem,
    GlButton,
    GlSkeletonLoading,
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
    };
  },
  computed: {
    ...mapGetters(['targetNoteHash', 'descriptionVersions']),
    ...mapState(['isLoadingDescriptionVersion']),
    noteAnchorId() {
      return `note_${this.note.id}`;
    },
    isTargetNote() {
      return this.targetNoteHash === this.noteAnchorId;
    },
    iconHtml() {
      return spriteIcon(this.note.system_note_icon_name);
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
  },
  mounted() {
    initMRPopovers(this.$el.querySelectorAll('.gfm-merge_request'));
  },
  methods: {
    ...mapActions(['fetchDescriptionVersion', 'softDeleteDescriptionVersion']),
  },
};
</script>

<template>
  <timeline-entry-item
    :id="noteAnchorId"
    :class="{ target: isTargetNote, 'pr-0': shouldShowDescriptionVersion }"
    class="note system-note note-wrapper"
  >
    <div class="timeline-icon" v-html="iconHtml"></div>
    <div class="timeline-content">
      <div class="note-header">
        <note-header :author="note.author" :created-at="note.created_at" :note-id="note.id">
          <span v-safe-html="actionTextHtml"></span>
          <template v-if="canSeeDescriptionVersion" #extra-controls>
            &middot;
            <gl-button
              variant="link"
              :icon="descriptionVersionToggleIcon"
              data-testid="compare-btn"
              @click="toggleDescriptionVersion"
              >{{ __('Compare with previous version') }}</gl-button
            >
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
            <gl-skeleton-loading />
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
      </div>
    </div>
  </timeline-entry-item>
</template>
