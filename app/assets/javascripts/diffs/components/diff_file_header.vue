<script>
import _ from 'underscore';
import { mapActions, mapGetters } from 'vuex';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';
import { truncateSha } from '~/lib/utils/text_utility';
import { __, s__, sprintf } from '~/locale';
import EditButton from './edit_button.vue';

export default {
  components: {
    ClipboardButton,
    EditButton,
    Icon,
    FileIcon,
  },
  directives: {
    Tooltip,
  },
  props: {
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
  },
  data() {
    return {
      blobForkSuggestion: null,
    };
  },
  computed: {
    ...mapGetters('diffs', ['diffHasExpandedDiscussions', 'diffHasDiscussions']),
    hasExpandedDiscussions() {
      return this.diffHasExpandedDiscussions(this.diffFile);
    },
    icon() {
      if (this.diffFile.submodule) {
        return 'archive';
      }

      return this.diffFile.blob.icon;
    },
    titleLink() {
      if (this.diffFile.submodule) {
        return this.diffFile.submoduleTreeUrl || this.diffFile.submoduleLink;
      }

      return `#${this.diffFile.fileHash}`;
    },
    filePath() {
      if (this.diffFile.submodule) {
        return `${this.diffFile.filePath} @ ${truncateSha(this.diffFile.blob.id)}`;
      }

      if (this.diffFile.deletedFile) {
        return sprintf(__('%{filePath} deleted'), { filePath: this.diffFile.filePath }, false);
      }

      return this.diffFile.filePath;
    },
    titleTag() {
      return this.diffFile.fileHash ? 'a' : 'span';
    },
    isUsingLfs() {
      return this.diffFile.storedExternally && this.diffFile.externalStorage === 'lfs';
    },
    collapseIcon() {
      return this.expanded ? 'chevron-down' : 'chevron-right';
    },
    viewFileButtonText() {
      const truncatedContentSha = _.escape(truncateSha(this.diffFile.contentSha));
      return sprintf(
        s__('MergeRequests|View file @ %{commitId}'),
        {
          commitId: `<span class="commit-sha">${truncatedContentSha}</span>`,
        },
        false,
      );
    },
    viewReplacedFileButtonText() {
      const truncatedBaseSha = _.escape(truncateSha(this.diffFile.diffRefs.baseSha));
      return sprintf(
        s__('MergeRequests|View replaced file @ %{commitId}'),
        {
          commitId: `<span class="commit-sha">${truncatedBaseSha}</span>`,
        },
        false,
      );
    },
    gfmCopyText() {
      return `\`${this.diffFile.filePath}\``;
    },
  },
  methods: {
    ...mapActions('diffs', ['toggleFileDiscussions']),
    handleToggleFile(e, checkTarget) {
      if (
        !checkTarget ||
        e.target === this.$refs.header ||
        (e.target.classList && e.target.classList.contains('diff-toggle-caret'))
      ) {
        this.$emit('toggleFile');
      }
    },
    showForkMessage() {
      this.$emit('showForkMessage');
    },
    handleToggleDiscussions() {
      this.toggleFileDiscussions(this.diffFile);
    },
  },
};
</script>

<template>
  <div
    ref="header"
    class="js-file-title file-title file-title-flex-parent"
    @click="handleToggleFile($event, true)"
  >
    <div class="file-header-content">
      <icon
        v-if="collapsible"
        :name="collapseIcon"
        :size="16"
        aria-hidden="true"
        class="svg-icon diff-toggle-caret append-right-5"
        @click.stop="handleToggle"
      />
      <a
        v-once
        ref="titleWrapper"
        :href="titleLink"
        class="append-right-4"
      >
        <file-icon
          :file-name="filePath"
          :size="18"
          aria-hidden="true"
          css-classes="svg-icon js-file-icon append-right-5"
        />
        <span v-if="diffFile.renamedFile">
          <strong
            v-tooltip
            :title="diffFile.oldPath"
            class="file-title-name"
            data-container="body"
          >
            {{ diffFile.oldPath }}
          </strong>
          →
          <strong
            v-tooltip
            :title="diffFile.newPath"
            class="file-title-name"
            data-container="body"
          >
            {{ diffFile.newPath }}
          </strong>
        </span>

        <strong
          v-tooltip
          v-else
          :title="filePath"
          class="file-title-name"
          data-container="body"
        >
          {{ filePath }}
        </strong>
      </a>

      <clipboard-button
        :title="__('Copy file path to clipboard')"
        :text="diffFile.filePath"
        :gfm="gfmCopyText"
        css-class="btn-default btn-transparent btn-clipboard"
        svg-css-class="svg-icon"
      />

      <small
        v-if="diffFile.modeChanged"
        ref="fileMode"
      >
        {{ diffFile.aMode }} → {{ diffFile.bMode }}
      </small>

      <span
        v-if="isUsingLfs"
        class="label label-lfs append-right-5"
      >
        {{ __('LFS') }}
      </span>
    </div>

    <div
      v-if="!diffFile.submodule && addMergeRequestButtons"
      class="file-actions d-none d-sm-block"
    >
      <template
        v-if="diffFile.blob && diffFile.blob.readableText"
      >
        <button
          :disabled="!diffHasDiscussions(diffFile)"
          :class="{ active: hasExpandedDiscussions }"
          :title="s__('MergeRequests|Toggle comments for this file')"
          class="js-btn-vue-toggle-comments btn"
          type="button"
          @click="handleToggleDiscussions"
        >
          <icon name="comment" class="svg-icon" />
        </button>

        <edit-button
          v-if="!diffFile.deletedFile"
          :can-current-user-fork="canCurrentUserFork"
          :edit-path="diffFile.editPath"
          :can-modify-blob="diffFile.canModifyBlob"
          @showForkMessage="showForkMessage"
        />
      </template>

      <a
        v-if="diffFile.replacedViewPath"
        :href="diffFile.replacedViewPath"
        class="btn view-file js-view-file"
        v-html="viewReplacedFileButtonText"
      >
      </a>
      <a
        :href="diffFile.viewPath"
        class="btn view-file js-view-file"
        v-html="viewFileButtonText"
      >
      </a>

      <a
        v-tooltip
        v-if="diffFile.externalUrl"
        :href="diffFile.externalUrl"
        :title="`View on ${diffFile.formattedExternalUrl}`"
        target="_blank"
        rel="noopener noreferrer"
        class="btn btn-file-option"
      >
        <icon name="external-link" />
      </a>
    </div>
  </div>
</template>
