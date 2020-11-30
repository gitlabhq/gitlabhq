<script>
import { escape } from 'lodash';
import { mapActions, mapGetters } from 'vuex';
import {
  GlTooltipDirective,
  GlSafeHtmlDirective,
  GlIcon,
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlLoadingIcon,
} from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import { truncateSha } from '~/lib/utils/text_utility';
import { __, s__, sprintf } from '~/locale';
import { diffViewerModes } from '~/ide/constants';
import DiffStats from './diff_stats.vue';
import { scrollToElement } from '~/lib/utils/common_utils';
import { isCollapsed } from '../diff_file';
import { DIFF_FILE_HEADER } from '../i18n';

export default {
  components: {
    ClipboardButton,
    GlIcon,
    FileIcon,
    DiffStats,
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml: GlSafeHtmlDirective,
  },
  i18n: {
    ...DIFF_FILE_HEADER,
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
  },
  data() {
    return {
      moreActionsShown: false,
    };
  },
  computed: {
    ...mapGetters('diffs', ['diffHasExpandedDiscussions', 'diffHasDiscussions']),
    diffContentIDSelector() {
      return `#diff-content-${this.diffFile.file_hash}`;
    },

    titleLink() {
      if (this.diffFile.submodule) {
        return this.diffFile.submodule_tree_url || this.diffFile.submodule_link;
      }

      if (!this.discussionPath) {
        return this.diffContentIDSelector;
      }

      return this.discussionPath;
    },
    submoduleDiffCompareLinkText() {
      if (this.diffFile.submodule_compare) {
        const truncatedOldSha = escape(truncateSha(this.diffFile.submodule_compare.old_sha));
        const truncatedNewSha = escape(truncateSha(this.diffFile.submodule_compare.new_sha));
        return sprintf(
          s__('Compare %{oldCommitId}...%{newCommitId}'),
          {
            oldCommitId: `<span class="commit-sha">${truncatedOldSha}</span>`,
            newCommitId: `<span class="commit-sha">${truncatedNewSha}</span>`,
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
    collapseIcon() {
      return this.expanded ? 'chevron-down' : 'chevron-right';
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
      return this.diffFile.viewer.name === diffViewerModes.mode_changed;
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
  },
  methods: {
    ...mapActions('diffs', [
      'toggleFileDiscussions',
      'toggleFileDiscussionWrappers',
      'toggleFullDiff',
      'toggleActiveFileByHash',
    ]),
    handleToggleFile() {
      this.$emit('toggleFile');
    },
    showForkMessage(e) {
      if (this.canCurrentUserFork && !this.diffFile.can_modify_blob) {
        e.preventDefault();
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
          this.toggleActiveFileByHash(this.diffFile.file_hash);
        }
      }
    },
    setMoreActionsShown(val) {
      this.moreActionsShown = val;
    },
  },
};
</script>

<template>
  <div
    ref="header"
    :class="{ 'gl-z-dropdown-menu!': moreActionsShown }"
    class="js-file-title file-title file-title-flex-parent"
    @click.self="handleToggleFile"
  >
    <div class="file-header-content">
      <gl-icon
        v-if="collapsible"
        ref="collapseIcon"
        :name="collapseIcon"
        :size="16"
        class="diff-toggle-caret gl-mr-2"
        @click.stop="handleToggleFile"
      />
      <a
        ref="titleWrapper"
        :v-once="!viewDiffsFileByFile"
        class="gl-mr-2 gl-text-decoration-none! gl-word-break-all"
        :href="titleLink"
        @click="handleFileNameClick"
      >
        <file-icon
          :file-name="filePath"
          :size="18"
          aria-hidden="true"
          css-classes="gl-mr-2"
          :submodule="diffFile.submodule"
        />
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
          data-qa-selector="file_name_content"
        >
          {{ filePath }}
        </strong>
      </a>

      <clipboard-button
        :title="__('Copy file path')"
        :text="diffFile.file_path"
        :gfm="gfmCopyText"
        data-testid="diff-file-copy-clipboard"
        category="tertiary"
        data-track-event="click_copy_file_button"
        data-track-label="diff_copy_file_path_button"
        data-track-property="diff_copy_file"
      />

      <small v-if="isModeChanged" ref="fileMode" class="mr-1">
        {{ diffFile.a_mode }} → {{ diffFile.b_mode }}
      </small>

      <span v-if="isUsingLfs" class="badge label label-lfs gl-mr-2"> {{ __('LFS') }} </span>
    </div>

    <div
      v-if="!diffFile.submodule && addMergeRequestButtons"
      class="file-actions d-flex align-items-center gl-ml-auto gl-align-self-start"
    >
      <diff-stats :added-lines="diffFile.added_lines" :removed-lines="diffFile.removed_lines" />
      <gl-button-group class="gl-pt-0!">
        <gl-button
          v-if="diffFile.external_url"
          ref="externalLink"
          v-gl-tooltip.hover
          :href="diffFile.external_url"
          :title="`View on ${diffFile.formatted_external_url}`"
          target="_blank"
          data-track-event="click_toggle_external_button"
          data-track-label="diff_toggle_external_button"
          data-track-property="diff_toggle_external"
          icon="external-link"
        />
        <gl-dropdown
          v-gl-tooltip.hover.focus="$options.i18n.optionsDropdownTitle"
          right
          toggle-class="btn-icon js-diff-more-actions"
          class="gl-pt-0!"
          @show="setMoreActionsShown(true)"
          @hidden="setMoreActionsShown(false)"
        >
          <template #button-content>
            <gl-icon name="ellipsis_v" class="mr-0" />
            <span class="sr-only">{{ $options.i18n.optionsDropdownTitle }}</span>
          </template>
          <gl-dropdown-item
            v-if="diffFile.replaced_view_path"
            ref="replacedFileButton"
            :href="diffFile.replaced_view_path"
            target="_blank"
          >
            {{ viewReplacedFileButtonText }}
          </gl-dropdown-item>
          <gl-dropdown-item ref="viewButton" :href="diffFile.view_path" target="_blank">
            {{ viewFileButtonText }}
          </gl-dropdown-item>
          <template v-if="showEditButton">
            <gl-dropdown-item
              v-if="diffFile.edit_path"
              ref="editButton"
              :href="diffFile.edit_path"
              class="js-edit-blob"
              @click="showForkMessage"
            >
              {{ __('Edit in single-file editor') }}
            </gl-dropdown-item>
            <gl-dropdown-item
              v-if="diffFile.edit_path"
              ref="ideEditButton"
              :href="diffFile.ide_edit_path"
              class="js-ide-edit-blob"
            >
              {{ __('Edit in Web IDE') }}
            </gl-dropdown-item>
          </template>

          <template v-if="!isCollapsed">
            <gl-dropdown-divider
              v-if="!diffFile.is_fully_expanded || diffHasDiscussions(diffFile)"
            />

            <gl-dropdown-item
              v-if="diffHasDiscussions(diffFile)"
              ref="toggleDiscussionsButton"
              data-qa-selector="toggle_comments_button"
              @click="toggleFileDiscussionWrappers(diffFile)"
            >
              <template v-if="diffHasExpandedDiscussions(diffFile)">
                {{ __('Hide comments on this file') }}
              </template>
              <template v-else>
                {{ __('Show comments on this file') }}
              </template>
            </gl-dropdown-item>
            <gl-dropdown-item
              v-if="!diffFile.is_fully_expanded"
              ref="expandDiffToFullFileButton"
              :disabled="diffFile.isLoadingFullFile"
              @click="toggleFullDiff(diffFile.file_path)"
            >
              <gl-loading-icon v-if="diffFile.isLoadingFullFile" inline />
              {{ expandDiffToFullFileTitle }}
            </gl-dropdown-item>
          </template>
        </gl-dropdown>
      </gl-button-group>
    </div>

    <div
      v-if="diffFile.submodule_compare"
      class="file-actions d-none d-sm-flex align-items-center flex-wrap"
    >
      <gl-button
        v-gl-tooltip.hover
        v-safe-html="submoduleDiffCompareLinkText"
        class="submodule-compare"
        :title="s__('Compare submodule commit revisions')"
        :href="diffFile.submodule_compare.url"
      />
    </div>
  </div>
</template>
