<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { n__ } from '~/locale';
import ChangedFileIcon from '~/vue_shared/components/changed_file_icon.vue';
import MrFileIcon from './mr_file_icon.vue';
import NewDropdown from './new_dropdown/index.vue';

export default {
  name: 'FileRowExtra',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    NewDropdown,
    ChangedFileIcon,
    MrFileIcon,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
    dropdownOpen: {
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
    isTree() {
      return this.file.type === 'tree';
    },
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

      return n__('%d changed file', '%d changed files', this.changesCount);
    },
    showTreeChangesCount() {
      return this.isTree && this.changesCount > 0 && !this.file.opened;
    },
    isModified() {
      return this.file.changed || this.file.tempFile || this.file.staged || this.file.prevPath;
    },
    showChangedFileIcon() {
      return !this.isTree && this.isModified;
    },
  },
};
</script>

<template>
  <div class="ide-file-icon-holder gl-float-right">
    <mr-file-icon v-if="file.mrChange" />
    <span v-if="showTreeChangesCount" class="ide-tree-changes">
      {{ changesCount }}
      <gl-icon
        v-gl-tooltip.left.viewport
        :title="folderChangesTooltip"
        :size="12"
        data-container="body"
        data-placement="right"
        name="file-modified"
        class="ide-file-modified gl-ml-2"
      />
    </span>
    <changed-file-icon
      v-else-if="showChangedFileIcon"
      :file="file"
      :show-tooltip="true"
      :show-staged-icon="false"
    />
    <new-dropdown
      :type="file.type"
      :path="file.path"
      :is-open="dropdownOpen"
      class="gl-ml-3"
      v-on="$listeners"
    />
  </div>
</template>
