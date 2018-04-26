<script>
import BlobForkSuggestion from '~/blob/blob_fork_suggestion';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';
import { truncateSha } from '~/lib/utils/text_utility.js';
import EditButton from './edit_button.vue';

export default {
  components: {
    ClipboardButton,
    Icon,
    EditButton,
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
    discussionsExpanded: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
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

      return this.diffFile.filePath;
    },
    titleTag() {
      return this.diffFile.fileHash ? 'a' : 'span';
    },
    baseSha() {
      return this.diffFile.diffRefs.baseSha;
    },
    contentSha() {
      return this.diffFile.contentSha;
    },
    truncatedBaseSha() {
      return truncateSha(this.baseSha);
    },
    truncatedContentSha() {
      return truncateSha(this.contentSha);
    },
    imageDiff() {
      return !this.diffFile.text;
    },
    replacedFile() {
      return !(this.diffFile.newFile || this.diffFile.deletedFile);
    },
    lfs() {
      return this.diffFile.storedExternally && this.diffFile.externalStorage === 'lfs';
    },
    collapseIcon() {
      return this.expanded ? 'chevron-down' : 'chevron-right';
    },
    isDiscussionsExpanded() {
      return this.discussionsExpanded && this.expanded;
    },
  },
  mounted() {
    new BlobForkSuggestion({
      openButtons: $(this.$el).find('.js-edit-blob-link-fork-toggler'),
      forkButtons: $(this.$el).find('.js-fork-suggestion-button'),
      cancelButtons: $(this.$el).find('.js-cancel-fork-suggestion-button'),
      suggestionSections: $(this.$el).find('.js-file-fork-suggestion-section'),
      actionTextPieces: $(this.$el).find('.js-file-fork-suggestion-section-action'),
    }).init();
  },
  methods: {
    handleToggle(e, checkTarget) {
      if (checkTarget) {
        if (e.target === this.$refs.header) {
          this.$emit('toggleFile');
        }
      } else {
        this.$emit('toggleFile');
      }
    },
  },
};
</script>

<template>
  <div
    class="js-file-title file-title file-title-flex-parent"
    @click="handleToggle($event, true)"
    ref="header"
  >
    <div class="file-header-content">
      <icon
        v-if="collapsible"
        :name="collapseIcon"
        @click.stop="handleToggle"
        :size="16"
        aria-hidden="true"
        class="diff-toggle-caret"
      />
      <component
        ref="titleWrapper"
        :is="titleTag"
        :href="titleLink"
      >
        <i class="fa fa-fw" :class="`fa-${icon}`"></i>
        <span v-if="diffFile.renamedFile">
          <strong
            class="file-title-name"
            v-tooltip
            :title="diffFile.oldPath"
            data-container="body"
          >
            {{ diffFile.oldPath }}
          </strong>
          &rarr;
          <strong
            class="file-title-name"
            v-tooltip
            :title="diffFile.newPath"
            data-container="body"
          >
            {{ diffFile.newPath }}
          </strong>
        </span>

        <strong
          v-else
          class="file-title-name"
          v-tooltip
          :title="filePath"
          data-container="body"
        >
          {{ filePath }}
          <span v-if="diffFile.deletedFile">
            deleted
          </span>
        </strong>
      </component>

      <clipboard-button
        title="Copy file path to clipboard"
        :text="diffFile.filePath"
        css-class="btn-default btn-transparent btn-clipboard"
      />

      <small
        v-if="diffFile.modeChanged"
        ref="fileMode"
      >
        {{ diffFile.aMode }} → {{ diffFile.bMode }}
      </small>

      <span
        v-if="lfs"
        class="label label-lfs append-right-5"
      >
        LFS
      </span>
    </div>

    <div
      v-if="!diffFile.submodule && addMergeRequestButtons"
      class="file-actions hidden-xs"
    >
      <template
        v-if="diffFile.blob && diffFile.blob.readableText"
      >
        <button
          :class="{ active: isDiscussionsExpanded }"
          class="btn"
          title="Toggle comments for this file"
          type="button"
        >
          <icon name="comment" />
        </button>

        <edit-button
          :edit-path="diffFile.editPath"
        />
      </template>

      <a
        v-if="diffFile.replacedViewPath"
        class="btn view-file js-view-file"
        :href="diffFile.replacedViewPath"
      >
        View replaced file @ <span class="commit-sha">{{ truncatedBaseSha }}</span>
      </a>
      <a
        class="btn view-file js-view-file"
        :href="diffFile.viewPath"
      >
        View file @ <span class="commit-sha">{{ truncatedContentSha }}</span>
      </a>

      <button
        v-if="diffFile.environment"
      >
        View on environment
        <!-- = view_on_environment_button(diff_file.content_sha, diff_file.file_path, environment) if environment -->
      </button>
    </div>
  </div>
</template>
