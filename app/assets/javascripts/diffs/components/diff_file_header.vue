<script>
import {
  GlTooltipDirective,
  GlBadge,
  GlButton,
  GlButtonGroup,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlFormCheckbox,
  GlLoadingIcon,
  GlAnimatedChevronRightDownIcon,
} from '@gitlab/ui';
import { escape } from 'lodash';
import { mapActions, mapState } from 'pinia';
import { keysFor, MR_TOGGLE_REVIEW } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import { truncateSha } from '~/lib/utils/text_utility';
import { sanitize } from '~/lib/dompurify';
import { __, s__, sprintf } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

import { createFileUrl, fileContentsId } from '~/diffs/components/diff_row_utils';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { DIFF_FILE_AUTOMATIC_COLLAPSE } from '../constants';
import diffsEventHub from '../event_hub';
import { DIFF_FILE_HEADER } from '../i18n';
import { collapsedType, isCollapsed } from '../utils/diff_file';
import { reviewable } from '../utils/file_reviews';
import DiffStats from './diff_stats.vue';

const createHotkeyHtml = (key) => `<kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`;

export default {
  components: {
    ClipboardButton,
    DiffStats,
    GlBadge,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    GlButton,
    GlButtonGroup,
    GlFormCheckbox,
    GlLoadingIcon,
    GlAnimatedChevronRightDownIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  i18n: {
    ...DIFF_FILE_HEADER,
    compareButtonLabel: __('Compare submodule commit revisions'),
    fileModeTooltip: __('File permissions'),
  },
  props: {
    discussionPath: {
      type: String,
      required: false,
      default: '',
    },
    diffFile: {
      type: Object,
      required: true,
    },
    collapsible: {
      type: Boolean,
      required: false,
      default: false,
    },
    addMergeRequestButtons: {
      type: Boolean,
      required: false,
      default: false,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: true,
    },
    canCurrentUserFork: {
      type: Boolean,
      required: true,
    },
    viewDiffsFileByFile: {
      type: Boolean,
      required: false,
      default: false,
    },
    showLocalFileReviews: {
      type: Boolean,
      required: false,
      default: false,
    },
    reviewed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(useLegacyDiffs, ['diffHasExpandedDiscussions', 'diffHasDiscussions']),
    ...mapState(useNotes, ['getNoteableData']),
    diffContentIDSelector() {
      return fileContentsId(this.diffFile);
    },
    diffUrl() {
      return createFileUrl(this.diffFile);
    },
    titleLink() {
      if (this.diffFile.submodule) {
        return this.diffFile.submodule_tree_url || this.diffFile.submodule_link;
      }

      if (!this.discussionPath) {
        return this.diffUrl;
      }

      return this.discussionPath;
    },
    submoduleDiffCompareLinkText() {
      if (this.diffFile.submodule_compare) {
        const truncatedOldSha = escape(truncateSha(this.diffFile.submodule_compare.old_sha));
        const truncatedNewSha = escape(truncateSha(this.diffFile.submodule_compare.new_sha));
        return sprintf(
          __('Compare %{old_commit} to %{new_commit}'),
          {
            old_commit: `<span class="commit-sha">${truncatedOldSha}</span>`,
            new_commit: `<span class="commit-sha">${truncatedNewSha}</span>`,
          },
          false,
        );
      }
      return null;
    },
    filePath() {
      if (this.diffFile.submodule) {
        return `${this.diffFile.file_path} @ ${truncateSha(this.diffFile.blob.id)}`;
      }

      if (this.diffFile.deleted_file) {
        return sprintf(__('%{filePath} deleted'), { filePath: this.diffFile.file_path }, false);
      }

      return this.diffFile.file_path;
    },
    isUsingLfs() {
      return this.diffFile.stored_externally && this.diffFile.external_storage === 'lfs';
    },
    isCollapsed() {
      return isCollapsed(this.diffFile, { fileByFile: this.viewDiffsFileByFile });
    },
    viewFileButtonText() {
      const truncatedContentSha = escape(truncateSha(this.diffFile.content_sha));
      return sprintf(
        s__('MergeRequests|View file @ %{commitId}'),
        { commitId: truncatedContentSha },
        false,
      );
    },
    viewReplacedFileButtonText() {
      const truncatedBaseSha = escape(truncateSha(this.diffFile.diff_refs.base_sha));
      return sprintf(s__('MergeRequests|View replaced file @ %{commitId}'), {
        commitId: truncatedBaseSha,
      });
    },
    gfmCopyText() {
      return `\`${this.diffFile.file_path}\``;
    },
    isFileRenamed() {
      return this.diffFile.renamed_file;
    },
    isModeChanged() {
      return this.diffFile.mode_changed;
    },
    expandDiffToFullFileTitle() {
      if (this.diffFile.isShowingFullFile) {
        return s__('MRDiff|Show changes only');
      }
      return s__('MRDiff|Show full file');
    },
    showEditButton() {
      return (
        this.diffFile.blob?.readable_text &&
        !this.diffFile.deleted_file &&
        (this.diffFile.edit_path || this.diffFile.ide_edit_path)
      );
    },
    isReviewable() {
      return reviewable(this.diffFile);
    },
    externalUrlLabel() {
      return sprintf(__('View on %{url}'), { url: this.diffFile.formatted_external_url });
    },
    labelToggleFile() {
      return this.expanded ? __('Hide file contents') : __('Show file contents');
    },
    showCommentButton() {
      return this.getNoteableData.current_user.can_create_note;
    },
    viewFileDropdownItem() {
      return {
        text: this.viewFileButtonText,
        href: this.diffFile.view_path,
        extraAttrs: {
          target: '_blank',
        },
      };
    },
    editInSingleFileEditorDropdownItem() {
      const href =
        this.canCurrentUserFork && this.diffFile.can_modify_blob && this.diffFile.edit_path;
      return {
        text: __('Edit in single-file editor'),
        action: this.showForkMessage,
        href,
        extraAttrs: {
          class: 'js-edit-blob',
        },
      };
    },
    openInWebIdeDropdownItem() {
      return {
        text: __('Open in Web IDE'),
        href: this.diffFile.ide_edit_path,
        extraAttrs: {
          target: '_blank',
          'data-testid': 'edit-in-ide-button',
          class: 'js-ide-edit-blob',
        },
      };
    },
    viewReplacedFileDropdownItem() {
      return {
        text: this.viewReplacedFileButtonText,
        href: this.diffFile.replaced_view_path,
        extraAttrs: {
          target: '_blank',
        },
      };
    },
    toggleDiscussionDropdownItem() {
      return {
        text: __('Hide comments on this file'),
        action: () => this.toggleFileDiscussionWrappers(this.diffFile),
        extraAttrs: {
          'data-testid': 'toggle-comments-button',
        },
      };
    },

    toggleDiffDropdownItem() {
      return {
        text: this.expandDiffToFullFileTitle,
        action: () => this.toggleFullDiff(this.diffFile.file_path),
        extraAttrs: {
          disabled: this.diffFile.isLoadingFullFile,
        },
      };
    },
  },
  methods: {
    ...mapActions(useLegacyDiffs, [
      'toggleFileDiscussionWrappers',
      'toggleFullDiff',
      'setCurrentFileHash',
      'reviewFile',
      'setFileCollapsedByUser',
      'setFileForcedOpen',
      'toggleFileCommentForm',
    ]),
    fileReviewTooltip() {
      const { description } = MR_TOGGLE_REVIEW;
      const keys = keysFor(MR_TOGGLE_REVIEW);
      return shouldDisableShortcuts()
        ? description
        : sanitize(`${description} ${createHotkeyHtml(keys[0])}`);
    },
    handleToggleFile() {
      diffsEventHub.$emit('setFileActive', this.diffFile.file_hash);
      this.setFileForcedOpen({
        filePath: this.diffFile.file_path,
        forced: false,
      });
      this.$emit('toggleFile');
    },
    showForkMessage() {
      if (this.canCurrentUserFork && !this.diffFile.can_modify_blob) {
        this.$emit('showForkMessage');
      }
    },
    handleFileNameClick(e) {
      const isLinkToOtherPage =
        this.diffFile.submodule_tree_url || this.diffFile.submodule_link || this.discussionPath;

      if (!isLinkToOtherPage) {
        e.preventDefault();
        const selector = this.diffContentIDSelector;
        scrollToElement(document.querySelector(selector));
        window.location.hash = selector;
        if (!this.viewDiffsFileByFile) {
          this.setCurrentFileHash(this.diffFile.file_hash);
        }
      }
    },
    toggleReview(newReviewedStatus) {
      // this is the easiest way to hide an already open tooltip that triggers on focus
      document.activeElement.blur();
      const autoCollapsed =
        this.isCollapsed && collapsedType(this.diffFile) === DIFF_FILE_AUTOMATIC_COLLAPSE;
      const open = this.expanded;
      const closed = !open;
      const reviewed = newReviewedStatus;

      this.reviewFile({ file: this.diffFile, reviewed });

      if (reviewed && autoCollapsed) {
        this.setFileCollapsedByUser({
          filePath: this.diffFile.file_path,
          collapsed: true,
        });
      }

      if ((open && reviewed) || (closed && !reviewed)) {
        this.setFileForcedOpen({
          filePath: this.diffFile.file_path,
          forced: false,
        });
        this.$emit('toggleFile');
      }
    },
  },
};
</script>

<template>
  <div
    ref="header"
    class="js-file-title file-title file-title-flex-parent"
    data-testid="file-title-container"
    :data-qa-file-name="filePath"
    @click.self="handleToggleFile"
  >
    <div class="file-header-content">
      <gl-button
        v-if="collapsible"
        ref="collapseButton"
        class="btn-icon gl-mr-2"
        category="tertiary"
        size="small"
        :aria-label="labelToggleFile"
        @click.stop="handleToggleFile"
      >
        <gl-animated-chevron-right-down-icon :is-on="expanded" />
      </gl-button>
      <a
        :v-once="!viewDiffsFileByFile"
        class="gl-mr-2 gl-break-all !gl-no-underline"
        :href="titleLink"
        data-testid="file-title"
        @click="handleFileNameClick"
      >
        <span v-if="isFileRenamed">
          <strong
            v-gl-tooltip
            v-safe-html="diffFile.old_path_html"
            :title="diffFile.old_path"
            class="file-title-name"
          ></strong>
          →
          <strong
            v-gl-tooltip
            v-safe-html="diffFile.new_path_html"
            :title="diffFile.new_path"
            class="file-title-name"
          ></strong>
        </span>

        <strong
          v-else
          v-gl-tooltip
          :title="filePath"
          class="file-title-name"
          data-container="body"
          data-testid="file-name-content"
        >
          {{ filePath }}
        </strong>
      </a>

      <clipboard-button
        :title="__('Copy file path')"
        :text="diffFile.file_path"
        :gfm="gfmCopyText"
        size="small"
        data-testid="diff-file-copy-clipboard"
        category="tertiary"
        data-track-action="click_copy_file_button"
        data-track-label="diff_copy_file_path_button"
        data-track-property="diff_copy_file"
      />

      <small
        v-if="isModeChanged"
        ref="fileMode"
        v-gl-tooltip.hover.focus
        class="gl-mr-2 gl-text-subtle"
        :title="$options.i18n.fileModeTooltip"
      >
        {{ diffFile.a_mode }} → {{ diffFile.b_mode }}
      </small>

      <gl-badge v-if="isUsingLfs" variant="neutral" class="gl-mr-2" data-testid="label-lfs">{{
        __('LFS')
      }}</gl-badge>
    </div>

    <div
      v-if="!diffFile.submodule && addMergeRequestButtons"
      class="file-actions gl-ml-auto gl-flex gl-items-center gl-self-start"
    >
      <diff-stats
        :diff-file="diffFile"
        :added-lines="diffFile.added_lines"
        :removed-lines="diffFile.removed_lines"
      />
      <gl-form-checkbox
        v-if="isReviewable && showLocalFileReviews"
        v-gl-tooltip.hover.focus.left.html="fileReviewTooltip"
        data-testid="fileReviewCheckbox"
        class="-gl-mb-3 gl-mr-5 gl-flex gl-items-center"
        :checked="reviewed"
        @change="toggleReview"
      >
        {{ $options.i18n.fileReviewLabel }}
      </gl-form-checkbox>
      <gl-button
        v-if="showCommentButton"
        v-gl-tooltip.hover.focus
        :title="__('Comment on this file')"
        :aria-label="__('Comment on this file')"
        icon="comment"
        category="tertiary"
        size="small"
        class="btn-icon gl-mr-3"
        data-testid="comment-files-button"
        @click="toggleFileCommentForm(diffFile.file_path)"
      />
      <gl-button-group class="!gl-pt-0">
        <gl-button
          v-if="diffFile.external_url"
          ref="externalLink"
          v-gl-tooltip.hover.focus
          :href="diffFile.external_url"
          :title="externalUrlLabel"
          :aria-label="externalUrlLabel"
          target="_blank"
          data-track-action="click_toggle_external_button"
          data-track-label="diff_toggle_external_button"
          data-track-property="diff_toggle_external"
          icon="external-link"
        />
        <gl-disclosure-dropdown
          v-gl-tooltip.hover.focus="$options.i18n.optionsDropdownTitle"
          no-caret
          icon="ellipsis_v"
          size="small"
          category="tertiary"
          right
          toggle-class="btn-icon js-diff-more-actions"
          data-testid="options-dropdown-button"
        >
          <gl-disclosure-dropdown-item ref="viewButton" :item="viewFileDropdownItem" />
          <template v-if="showEditButton">
            <gl-disclosure-dropdown-item
              v-if="diffFile.edit_path"
              ref="editButton"
              :item="editInSingleFileEditorDropdownItem"
            />
            <gl-disclosure-dropdown-item
              v-if="diffFile.ide_edit_path"
              ref="ideEditButton"
              :item="openInWebIdeDropdownItem"
            />
            <gl-disclosure-dropdown-item
              v-if="diffFile.replaced_view_path"
              ref="replacedFileButton"
              :item="viewReplacedFileDropdownItem"
            />
          </template>

          <template v-if="!isCollapsed">
            <gl-disclosure-dropdown-group
              v-if="!diffFile.is_fully_expanded || diffHasDiscussions(diffFile)"
              bordered
            >
              <gl-disclosure-dropdown-item
                v-if="diffHasDiscussions(diffFile)"
                ref="toggleDiscussionsButton"
                :item="toggleDiscussionDropdownItem"
              >
                <template #list-item>
                  <template v-if="diffHasExpandedDiscussions(diffFile)">
                    {{ __('Hide comments on this file') }}
                  </template>
                  <template v-else>
                    {{ __('Show comments on this file') }}
                  </template>
                </template>
              </gl-disclosure-dropdown-item>
              <gl-disclosure-dropdown-item
                v-if="!diffFile.is_fully_expanded"
                ref="expandDiffToFullFileButton"
                :item="toggleDiffDropdownItem"
              >
                <template #list-item>
                  <gl-loading-icon v-if="diffFile.isLoadingFullFile" size="sm" inline />
                  {{ expandDiffToFullFileTitle }}
                </template>
              </gl-disclosure-dropdown-item>
            </gl-disclosure-dropdown-group>
          </template>
        </gl-disclosure-dropdown>
      </gl-button-group>
    </div>

    <div
      v-if="diffFile.submodule_compare"
      class="file-actions gl-hidden gl-flex-wrap gl-items-center @sm/panel:gl-flex"
    >
      <gl-button
        v-gl-tooltip.hover
        v-safe-html="submoduleDiffCompareLinkText"
        class="submodule-compare gl-inline-block"
        :title="$options.i18n.compareButtonLabel"
        :aria-label="$options.i18n.compareButtonLabel"
        :href="diffFile.submodule_compare.url"
      />
    </div>
  </div>
</template>
