<script>
import Icon from '~/vue_shared/components/icon.vue';
import FileHeader from '~/vue_shared/components/file_row_header.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import ChangedFileIcon from '~/vue_shared/components/changed_file_icon.vue';

export default {
  name: 'FileRow',
  components: {
    FileHeader,
    FileIcon,
    Icon,
    ChangedFileIcon,
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
    extraComponent: {
      type: Object,
      required: false,
      default: null,
    },
    hideExtraOnTree: {
      type: Boolean,
      required: false,
      default: false,
    },
    showChangedIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      dropdownOpen: false,
    };
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
        'is-active': this.isBlob && this.file.active,
        folder: this.isTree,
        'is-open': this.file.opened,
      };
    },
    childFilesLevel() {
      return this.file.isHeader ? 0 : this.level + 1;
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

      return this.$router.currentRoute.path === `/project${this.file.url}`;
    },
    toggleDropdown(val) {
      this.dropdownOpen = val;
    },
  },
};
</script>

<template>
  <div>
    <file-header v-if="file.isHeader" :path="file.path" />
    <div
      v-else
      :class="fileClass"
      :title="file.name"
      class="file-row"
      role="button"
      @click="clickFile"
      @mouseleave="toggleDropdown(false)"
    >
      <div class="file-row-name-container">
        <span ref="textOutput" :style="levelIndentation" class="file-row-name str-truncated">
          <file-icon
            v-if="!showChangedIcon || file.type === 'tree'"
            class="file-row-icon"
            :file-name="file.name"
            :loading="file.loading"
            :folder="isTree"
            :opened="file.opened"
            :size="16"
          />
          <changed-file-icon v-else :file="file" :size="16" class="append-right-5" />
          {{ file.name }}
        </span>
        <component
          :is="extraComponent"
          v-if="extraComponent && !(hideExtraOnTree && file.type === 'tree')"
          :file="file"
          :dropdown-open="dropdownOpen"
          @toggle="toggleDropdown($event)"
        />
      </div>
    </div>
    <template v-if="file.opened || file.isHeader">
      <file-row
        v-for="childFile in file.tree"
        :key="childFile.key"
        :file="childFile"
        :level="childFilesLevel"
        :hide-extra-on-tree="hideExtraOnTree"
        :extra-component="extraComponent"
        :show-changed-icon="showChangedIcon"
        @toggleTreeOpen="toggleTreeOpen"
        @clickFile="clickedFile"
      />
    </template>
  </div>
</template>

<style>
.file-row {
  display: flex;
  align-items: center;
  height: 32px;
  padding: 4px 8px;
  margin-left: -8px;
  margin-right: -8px;
  border-radius: 3px;
  text-align: left;
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
  display: flex;
  width: 100%;
  align-items: center;
  overflow: visible;
}

.file-row-name {
  display: inline-block;
  flex: 1;
  max-width: inherit;
  height: 19px;
  line-height: 16px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.file-row-name .file-row-icon {
  margin-right: 2px;
  vertical-align: middle;
}
</style>
