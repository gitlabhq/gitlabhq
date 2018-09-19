<script>
import { mapGetters } from 'vuex';
import { n__, __, sprintf } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import NewDropdown from './new_dropdown/index.vue';
import ChangedFileIcon from './changed_file_icon.vue';
import MrFileIcon from './mr_file_icon.vue';

export default {
  name: 'FileRowExtra',
  directives: {
    tooltip,
  },
  components: {
    Icon,
    NewDropdown,
    ChangedFileIcon,
    MrFileIcon,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
    mouseOver: {
      type: Boolean,
      required: true,
    },
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
    showTreeChangesCount() {
      return this.file.type === 'tree' && this.changesCount > 0 && !this.file.opened;
    },
    showChangedFileIcon() {
      return this.file.changed || this.file.tempFile || this.file.staged;
    },
  },
};
</script>

<template>
  <div class="float-right ide-file-icon-holder">
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
        css-classes="prepend-left-5 ide-file-modified"
      />
    </span>
    <changed-file-icon
      v-else-if="showChangedFileIcon"
      :file="file"
      :show-tooltip="true"
      :show-staged-icon="true"
      :force-modified-icon="true"
    />
    <new-dropdown
      :type="file.type"
      :path="file.path"
      :mouse-over="mouseOver"
      class="prepend-left-8"
    />
  </div>
</template>
