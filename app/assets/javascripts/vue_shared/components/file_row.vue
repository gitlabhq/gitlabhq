<script>
import FileHeader from '~/vue_shared/components/file_row_header.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import { escapeFileUrl } from '~/lib/utils/url_utility';

export default {
  name: 'FileRow',
  components: {
    FileHeader,
    FileIcon,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
    level: {
      type: Number,
      required: true,
    },
    activeFile: {
      type: String,
      required: false,
      default: '',
    },
    viewedFiles: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    isTree() {
      return this.file.type === 'tree';
    },
    isBlob() {
      return this.file.type === 'blob';
    },
    levelIndentation() {
      return {
        marginLeft: this.level ? `${this.level * 16}px` : null,
      };
    },
    fileClass() {
      return {
        'file-open': this.isBlob && this.file.opened,
        'is-active': this.isBlob && (this.file.active || this.activeFile === this.file.fileHash),
        'is-viewed': this.isBlob && this.viewedFiles.includes(this.file.fileHash),
        'is-open': this.file.opened,
      };
    },
  },
  watch: {
    'file.active': function fileActiveWatch(active) {
      if (this.file.type === 'blob' && active) {
        this.scrollIntoView();
      }
    },
  },
  mounted() {
    if (this.hasPathAtCurrentRoute()) {
      this.scrollIntoView(true);
    }
  },
  methods: {
    toggleTreeOpen(path) {
      this.$emit('toggleTreeOpen', path);
    },
    clickedFile(path) {
      this.$emit('clickFile', path);
    },
    clickFile() {
      // Manual Action if a tree is selected/opened
      if (this.isTree && this.hasUrlAtCurrentRoute()) {
        this.toggleTreeOpen(this.file.path);
      }

      if (this.$router) this.$router.push(`/project${this.file.url}`);

      if (this.isBlob) this.clickedFile(this.file.path);
    },
    scrollIntoView(isInit = false) {
      const block = isInit && this.isTree ? 'center' : 'nearest';

      this.$el.scrollIntoView({
        behavior: 'smooth',
        block,
      });
    },
    hasPathAtCurrentRoute() {
      if (!this.$router || !this.$router.currentRoute) {
        return false;
      }

      // - strip route up to "/-/" and ending "/"
      const routePath = this.$router.currentRoute.path
        .replace(/^.*?[/]-[/]/g, '')
        .replace(/[/]$/g, '');

      // - strip ending "/"
      const filePath = this.file.path.replace(/[/]$/g, '');

      return filePath === routePath;
    },
    hasUrlAtCurrentRoute() {
      if (!this.$router || !this.$router.currentRoute) return true;

      return this.$router.currentRoute.path === `/project${escapeFileUrl(this.file.url)}`;
    },
  },
};
</script>

<template>
  <file-header v-if="file.isHeader" :path="file.path" />
  <div
    v-else
    :class="fileClass"
    :title="file.name"
    class="file-row text-left px-1 py-2 ml-n2 d-flex align-items-center"
    role="button"
    @click="clickFile"
    @mouseleave="$emit('mouseleave', $event)"
  >
    <div class="file-row-name-container w-100 d-flex align-items-center">
      <span
        ref="textOutput"
        :style="levelIndentation"
        class="file-row-name str-truncated d-inline-block"
        :class="[
          { 'folder font-weight-normal': isTree },
          fileClass['is-viewed'] ? 'font-weight-normal' : 'font-weight-bold',
        ]"
      >
        <file-icon
          class="file-row-icon align-middle mr-1"
          :class="{ 'text-secondary': file.type === 'tree' }"
          :file-name="file.name"
          :loading="file.loading"
          :folder="isTree"
          :opened="file.opened"
          :size="16"
        />
        {{ file.name }}
      </span>
      <slot></slot>
    </div>
  </div>
</template>

<style>
.file-row {
  height: 32px;
  border-radius: 3px;
  cursor: pointer;
}

.file-row:hover,
.file-row:focus {
  background: #f2f2f2;
}

.file-row:active {
  background: #dfdfdf;
}

.file-row.is-active {
  background: #f2f2f2;
}

.file-row-name-container {
  overflow: visible;
}

.file-row-name {
  flex: 1;
  max-width: inherit;
  height: 20px;
  line-height: 16px;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
