<script>
import Icon from '~/vue_shared/components/icon.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';

export default {
  name: 'FileRow',
  components: {
    FileIcon,
    Icon,
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
  },
  data() {
    return {
      mouseOver: false,
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
        marginLeft: `${this.level * 16}px`,
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
    clickFile() {
      // Manual Action if a tree is selected/opened
      if (this.isTree && this.hasUrlAtCurrentRoute()) {
        this.toggleTreeOpen(this.file.path);
      }

      if (this.$router) this.$router.push(`/project${this.file.url}`);
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
    toggleHover(over) {
      this.mouseOver = over;
    },
  },
};
</script>

<template>
  <div>
    <div
      :class="fileClass"
      class="file-row"
      role="button"
      @click="clickFile"
      @mouseover="toggleHover(true)"
      @mouseout="toggleHover(false)"
    >
      <div
        class="file-row-name-container"
      >
        <span
          :style="levelIndentation"
          class="file-row-name str-truncated"
        >
          <file-icon
            :file-name="file.name"
            :loading="file.loading"
            :folder="isTree"
            :opened="file.opened"
            :size="16"
          />
          {{ file.name }}
        </span>
        <component
          v-if="extraComponent"
          :is="extraComponent"
          :file="file"
          :mouse-over="mouseOver"
        />
      </div>
    </div>
    <template v-if="file.opened">
      <file-row
        v-for="childFile in file.tree"
        :key="childFile.key"
        :file="childFile"
        :level="level + 1"
        :extra-component="extraComponent"
        @toggleTreeOpen="toggleTreeOpen"
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
  height: 18px;
  line-height: 16px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.file-row-name svg {
  margin-right: 2px;
  vertical-align: middle;
}

.file-row-name .loading-container {
  display: inline-block;
  margin-right: 4px;
}
</style>
