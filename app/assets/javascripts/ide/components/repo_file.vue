<script>
import { mapActions, mapGetters } from 'vuex';
import { n__, __, sprintf } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';
import SkeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
import Icon from '~/vue_shared/components/icon.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import router from '../ide_router';
import NewDropdown from './new_dropdown/index.vue';
import FileStatusIcon from './repo_file_status_icon.vue';
import ChangedFileIcon from './changed_file_icon.vue';
import MrFileIcon from './mr_file_icon.vue';

export default {
  name: 'RepoFile',
  directives: {
    tooltip,
  },
  components: {
    SkeletonLoadingContainer,
    NewDropdown,
    FileStatusIcon,
    FileIcon,
    ChangedFileIcon,
    MrFileIcon,
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
  },
  data() {
    return {
      mouseOver: false,
    };
  },
  computed: {
    ...mapGetters([
      'getChangesInFolder',
      'getUnstagedFilesCountForPath',
      'getStagedFilesCountForPath',
    ]),
    folderUnstagedCount() {
      return this.getUnstagedFilesCountForPath(this.file.path);
    },
    folderStagedCount() {
      return this.getStagedFilesCountForPath(this.file.path);
    },
    changesCount() {
      return this.getChangesInFolder(this.file.path);
    },
    folderChangesTooltip() {
      if (this.changesCount === 0) return undefined;

      if (this.folderUnstagedCount > 0 && this.folderStagedCount === 0) {
        return n__('%d unstaged change', '%d unstaged changes', this.folderUnstagedCount);
      } else if (this.folderUnstagedCount === 0 && this.folderStagedCount > 0) {
        return n__('%d staged change', '%d staged changes', this.folderStagedCount);
      }

      return sprintf(__('%{unstaged} unstaged and %{staged} staged changes'), {
        unstaged: this.folderUnstagedCount,
        staged: this.folderStagedCount,
      });
    },
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
        'file-active': this.isBlob && this.file.active,
        folder: this.isTree,
        'is-open': this.file.opened,
      };
    },
    showTreeChangesCount() {
      return this.isTree && this.changesCount > 0 && !this.file.opened;
    },
    showChangedFileIcon() {
      return this.file.changed || this.file.tempFile || this.file.staged;
    },
  },
  mounted() {
    if (this.hasPathAtCurrentRoute()) {
      this.scrollIntoView(true);
    }
  },
  updated() {
    if (this.file.type === 'blob' && this.file.active) {
      this.scrollIntoView();
    }
  },
  methods: {
    ...mapActions(['toggleTreeOpen']),
    clickFile() {
      // Manual Action if a tree is selected/opened
      if (this.isTree && this.hasUrlAtCurrentRoute()) {
        this.toggleTreeOpen(this.file.path);
      }

      router.push(`/project${this.file.url}`);
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
      const filePath = this.file.path
        .replace(/[/]$/g, '');

      return filePath === routePath;
    },
    hasUrlAtCurrentRoute() {
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
      class="file"
      role="button"
      @click="clickFile"
      @mouseover="toggleHover(true)"
      @mouseout="toggleHover(false)"
    >
      <div
        class="file-name"
      >
        <span
          :style="levelIndentation"
          class="ide-file-name str-truncated"
        >
          <file-icon
            :file-name="file.name"
            :loading="file.loading"
            :folder="isTree"
            :opened="file.opened"
            :size="16"
          />
          {{ file.name }}
          <file-status-icon
            :file="file"
          />
        </span>
        <span class="float-right ide-file-icon-holder">
          <mr-file-icon
            v-if="file.mrChange"
          />
          <span
            v-if="showTreeChangesCount"
            class="ide-tree-changes"
          >
            {{ changesCount }}
            <icon
              v-tooltip
              :title="folderChangesTooltip"
              :size="12"
              data-container="body"
              data-placement="right"
              name="file-modified"
              css-classes="prepend-left-5 multi-file-modified"
            />
          </span>
          <changed-file-icon
            v-else-if="showChangedFileIcon"
            :file="file"
            :show-tooltip="true"
            :show-staged-icon="true"
            :force-modified-icon="true"
            class="float-right"
          />
        </span>
        <new-dropdown
          :type="file.type"
          :branch="file.branchId"
          :path="file.path"
          :mouse-over="mouseOver"
          class="float-right prepend-left-8"
        />
      </div>
    </div>
    <template v-if="file.opened">
      <repo-file
        v-for="childFile in file.tree"
        :key="childFile.key"
        :file="childFile"
        :level="level + 1"
      />
    </template>
  </div>
</template>
