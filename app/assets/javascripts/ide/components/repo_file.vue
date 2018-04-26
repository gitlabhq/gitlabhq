<script>
import { mapActions } from 'vuex';
import skeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
import fileIcon from '~/vue_shared/components/file_icon.vue';
import router from '../ide_router';
import newDropdown from './new_dropdown/index.vue';
import fileStatusIcon from './repo_file_status_icon.vue';
import changedFileIcon from './changed_file_icon.vue';
import mrFileIcon from './mr_file_icon.vue';

export default {
  name: 'RepoFile',
  components: {
    skeletonLoadingContainer,
    newDropdown,
    fileStatusIcon,
    fileIcon,
    changedFileIcon,
    mrFileIcon,
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
        <span class="float-right ide-file-icon-holder">
          <mr-file-icon
            v-if="file.mrChange"
          />
          <changed-file-icon
            v-if="file.changed || file.tempFile || file.staged"
            :file="file"
            :show-tooltip="true"
            :show-staged-icon="true"
            :force-modified-icon="true"
            class="pull-right"
          />
        </span>
        <new-dropdown
          v-if="isTree"
          :project-id="file.projectId"
          :branch="file.branchId"
          :path="file.path"
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
