<script>
  import { mapActions, mapState } from 'vuex';

  import timeAgoMixin from '~/vue_shared/mixins/timeago';
  import skeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
  import fileIcon from '~/vue_shared/components/file_icon.vue';
  import newDropdown from './new_dropdown/index.vue';

  import fileStatusIcon from 'ee/ide/components/repo_file_status_icon.vue'; // eslint-disable-line import/first
  import changedFileIcon from 'ee/ide/components/changed_file_icon.vue'; // eslint-disable-line import/first

  export default {
    name: 'RepoFile',
    components: {
      skeletonLoadingContainer,
      newDropdown,
      fileStatusIcon,
      fileIcon,
      changedFileIcon,
    },
    mixins: [
      timeAgoMixin,
    ],
    props: {
      file: {
        type: Object,
        required: true,
      },
      showExtraColumns: {
        type: Boolean,
        default: false,
      },
    },
    computed: {
      ...mapState([
        'leftPanelCollapsed',
      ]),
      isSubmodule() {
        return this.file.type === 'submodule';
      },
      isTree() {
        return this.file.type === 'tree';
      },
      levelIndentation() {
        if (this.file.level > 0) {
          return {
            marginLeft: `${this.file.level * 16}px`,
          };
        }
        return {};
      },
      shortId() {
        return this.file.id.substr(0, 8);
      },
      fileClass() {
        if (this.file.type === 'blob') {
          if (this.file.active) {
            return 'file-open file-active';
          }
          return this.file.opened ? 'file-open' : '';
        } else if (this.file.type === 'tree') {
          return 'folder';
        }
        return '';
      },
    },
    updated() {
      if (this.file.type === 'blob' && this.file.active) {
        this.$el.scrollIntoView();
      }
    },
    methods: {
      ...mapActions([
        'updateDelayViewerUpdated',
      ]),
      clickFile(row) {
        // Manual Action if a tree is selected/opened
        if (this.file.type === 'tree' && this.$router.currentRoute.path === `/project${row.url}`) {
          this.$store.dispatch('toggleTreeOpen', {
            endpoint: this.file.url,
            tree: this.file,
          });
        }

        const delayPromise = this.file.changed ?
          Promise.resolve() : this.updateDelayViewerUpdated(true);

        return delayPromise.then(() => {
          this.$router.push(`/project${row.url}`);
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
        @click="clickFile(file)"
      >
        <a
          class="ide-file-name str-truncated"
        >
          <file-icon
            :file-name="file.name"
            :loading="file.loading"
            :folder="file.type === 'tree'"
            :opened="file.opened"
            :style="levelIndentation"
            :size="16"
          />
          {{ file.name }}
          <file-status-icon :file="file" />
        </a>
        <new-dropdown
          v-if="isTree"
          :project-id="file.projectId"
          :branch="file.branchId"
          :path="file.path"
          :parent="file"
        />
        <changed-file-icon
          :file="file"
          v-if="file.changed || file.tempFile"
          class="prepend-top-5"
        />
        <template v-if="isSubmodule && file.id">
          @
          <span class="commit-sha">
            <a
              @click.stop
              :href="file.tree_url"
            >
              {{ shortId }}
            </a>
          </span>
        </template>
      </div>
    </div>
    <template
      v-if="file.opened"
    >
      <repo-file
        v-for="childFile in file.tree"
        :key="childFile.key"
        :file="childFile"
      />
    </template>
  </div>
</template>
