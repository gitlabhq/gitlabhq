<script>
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';

export default {
  components: {
    ClipboardButton,
    Icon,
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
  },
  computed: {
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
      return this.truncate(this.baseSha);
    },
    truncatedContentSha() {
      return this.truncate(this.contentSha);
    },
    imageDiff() {
      return !this.diffFile.text;
    },
    replacedFile() {
      return !(this.diffFile.newFile || this.diffFile.deletedFile);
    },
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
    truncate(sha) {
      return sha.slice(0, 8);
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
        @click.stop="handleToggle"
        name="chevron-down"
        aria-hidden="true"
        :size="16"
        class="diff-toggle-caret"
      />
      <div
        v-if="diffFile.submodule"
      >
        <span>
          <icon name="archive" />
          <strong
            v-html="diffFile.submoduleLink"
            class="file-title-name"
          ></strong>
          <clipboard-button
            :text="diffFile.submoduleLink"
            title="Copy file path to clipboard"
            css-class="btn-default btn-transparent btn-clipboard"
          />
        </span>
      </div>
      <template v-else>
        <component
          ref="titleWrapper"
          :is="titleTag"
          :href="`#${diffFile.fileHash}`"
        >
          <i class="fa fa-fw" :class="`fa-${diffFile.blob.icon}`"></i>
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
            :title="diffFile.oldPath"
            data-container="body"
          >
            {{ diffFile.filePath }}
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
      </template>
    </div>

    <div
      v-if="!diffFile.submodule && addMergeRequestButtons"
      class="file-actions hidden-xs"
    >
      <template
        v-if="diffFile.blob && diffFile.blob.readableText"
      >
        <button
          class="js-toggle-diff-comments btn"
          title="Toggle comments for this file"
          type="button"
          :class="{
            active: 'todo'
          }"
        >
          <icon name="comment" />
        </button>

        <a
          :href="diffFile.editPath"
          class="btn btn-default js-edit-blob"
        >
          Edit
        </a>
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
