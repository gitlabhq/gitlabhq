<script>
import { mapActions, mapGetters } from 'vuex';
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
  computed: {
    ...mapGetters(['getChangesInFolder']),
    folderChangedCount() {
      return this.getChangesInFolder(this.file.path);
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
  },
  updated() {
    if (this.file.type === 'blob' && this.file.active) {
      this.$el.scrollIntoView();
    }
  },
  methods: {
    ...mapActions(['toggleTreeOpen', 'updateDelayViewerUpdated']),
    clickFile() {
      // Manual Action if a tree is selected/opened
      if (this.isTree && this.$router.currentRoute.path === `/project${this.file.url}`) {
        this.toggleTreeOpen(this.file.path);
      }

      return this.updateDelayViewerUpdated(true).then(() => {
        router.push(`/project${this.file.url}`);
      });
    },
  },
};
</script>

<template>
  <div>
    <div
      class="file"
      :class="fileClass"
    >
      <div
        class="file-name"
        @click="clickFile"
        role="button"
      >
        <span
          class="ide-file-name str-truncated"
          :style="levelIndentation"
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
        <span class="pull-right">
          <mr-file-icon
            v-if="file.mrChange"
          />
          <span
            v-if="isTree && folderChangedCount > 0"
            class="ide-tree-changes"
          >
            {{ folderChangedCount }}
            <icon
              name="file-modified"
              :size="12"
              css-classes="prepend-left-5 multi-file-modified"
            />
          </span>
          <changed-file-icon
            v-else-if="file.changed || file.tempFile"
            :file="file"
          />
        </span>
        <new-dropdown
          v-if="isTree"
          :project-id="file.projectId"
          :branch="file.branchId"
          :path="file.path"
          class="pull-right prepend-left-8"
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
