<script>
import { mapGetters, mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    diffFiles: {
      type: Array,
      required: true,
    },
    activeFile: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      searchText: '',
      isStuck: false,
      showCurrentDiffTitle: false,
    };
  },
  computed: {
    ...mapGetters(['isInlineView', 'isParallelView']),
    sumAddedLines() {
      return this.sumValues('addedLines');
    },
    sumRemovedLines() {
      return this.sumValues('removedLines');
    },
    filteredDiffFiles() {
      return this.diffFiles.filter(file =>
        file.filePath.toLowerCase().includes(this.searchText.toLowerCase()),
      );
    },
    stickyClass() {
      return this.isStuck ? 'is-stuck' : '';
    },
  },
  mounted() {
    if (
      typeof CSS === 'undefined' ||
      !CSS.supports('(position: -webkit-sticky) or (position: sticky)')
    )
      return;

    document.addEventListener('scroll', this.handleScroll.bind(this), {
      passive: true,
    });
  },
  methods: {
    ...mapActions(['setDiffViewType']),
    handleScroll() {
      if (!this.$refs.stickyBar) return;

      const barPosition = this.$refs.stickyBar.offsetTop;
      const scrollPosition = window.scrollY;

      const top = Math.floor(barPosition - scrollPosition);

      this.isStuck = top < 112;
      this.showCurrentDiffTitle = top < 0;
    },
    sumValues(key) {
      return this.diffFiles.reduce((total, file) => total + file[key], 0);
    },
    fileChangedIcon(diffFile) {
      if (diffFile.deletedFile) {
        return 'file-deletion';
      } else if (diffFile.newFile) {
        return 'file-addition';
      }
      return 'file-modified';
    },
    fileChangedClass(diffFile) {
      if (diffFile.deletedFile) {
        return 'cred';
      } else if (diffFile.newFile) {
        return 'cgreen';
      }

      return '';
    },
    truncatedDiffPath(path) {
      const maxLength = 60;

      return path.length > maxLength ? `...${path.slice(0, maxLength)}` : path;
    },
  },
};
</script>

<template>
  <div
    v-if="diffFiles.length > 0"
    ref="stickyBar"
    class="content-block oneline-block diff-files-changed diff-files-changed-merge-request
    files-changed js-diff-files-changed"
    :class="stickyClass"
  >
    <div class="files-changed-inner">
      <div
        v-show="!showCurrentDiffTitle"
        class="inline-parallel-buttons hidden-xs hidden-sm"
      >
        <a
          class="hidden-xs btn btn-default"
          href="/fatihacet/test/merge_requests/5/diffs?w=1&TODO"
        >
          {{ __('Hide whitespace changes') }}
        </a>
        <div class="btn-group">
          <a
            @click.prevent="setDiffViewType()"
            :class="{ active: isInlineView }"
            id="inline-diff-btn"
            class="btn"
            data-view-type="inline"
            href="#"
          >
            {{ __('Inline') }}
          </a>
          <a
            @click.prevent="setDiffViewType(true)"
            :class="{ active: isParallelView }"
            id="parallel-diff-btn"
            class="btn"
            data-view-type="parallel"
            href="#"
          >
            {{ __('Side-by-side') }}
          </a>
        </div>
      </div>

      <div class="commit-stat-summary dropdown">
        Showing
        <button
          class="diff-stats-summary-toggler js-diff-stats-dropdown"
          data-toggle="dropdown"
          type="button"
          aria-expanded="false"
        >
          <span>
            {{ n__('%d changed file', '%d changed files', diffFiles.length) }}
          </span>
          <icon
            name="chevron-down"
            :size="8"
          />
        </button>
        <div class="dropdown-menu diff-file-changes">
          <div class="dropdown-input">
            <input
              v-model="searchText"
              type="search"
              class="dropdown-input-field"
              placeholder="Search files"
              autocomplete="off"
            />
            <i
              v-if="searchText.length === 0"
              aria-hidden="true"
              data-hidden="true"
              class="fa fa-search dropdown-input-search">
            </i>
            <i
              v-else
              role="button"
              aria-hidden="true"
              data-hidden="true"
              class="fa fa-times dropdown-input-search"
              @click="searchText = ''"
            ></i>
          </div>
          <ul>
            <li
              v-for="diffFile in filteredDiffFiles"
              :key="diffFile.name"
            >
              <a
                class="diff-changed-file"
                :href="`#${diffFile.fileHash}`"
                :title="diffFile.newPath"
              >
                <icon
                  :name="fileChangedIcon(diffFile)"
                  :size="16"
                  :class="fileChangedClass(diffFile)"
                  class="diff-file-changed-icon append-right-8"
                />
                <span class="diff-changed-file-content append-right-8">
                  <strong
                    v-if="diffFile.blobName"
                    class="diff-changed-file-name"
                  >
                    {{ diffFile.blobName }}
                  </strong>
                  <strong
                    v-else
                    class="diff-changed-blank-file-name"
                  >
                    {{ s__('Diffs|No file name available') }}
                  </strong>
                  <span class="diff-changed-file-path prepend-top-5">
                    {{ truncatedDiffPath(diffFile.blobPath) }}
                  </span>
                </span>
                <span class="diff-changed-stats">
                  <span class="cgreen">
                    +{{ diffFile.addedLines }}
                  </span>
                  <span class="cred">
                    -{{ diffFile.removedLines }}
                  </span>
                </span>
              </a>
            </li>

            <li
              v-show="filteredDiffFiles.length === 0"
              class="dropdown-menu-empty-item"
            >
              <a href="javascript:void(0)">
                No files found
              </a>
            </li>
          </ul>
        </div>

        <span
          v-show="!isStuck"
          class="diff-stats-additions-deletions-expanded"
          id="diff-stats"
        >
          with
          <strong class="cgreen">
            {{ n__('%d addition', '%d additions', sumAddedLines) }}
          </strong>
          and
          <strong class="cred">
            {{ n__('%d deletion', '%d deletions', sumRemovedLines) }}
          </strong>
        </span>

        <span
          v-show="activeFile"
          class="prepend-left-5"
        >
          {{ truncatedDiffPath(activeFile) }}
        </span>
      </div>
    </div>
  </div>
</template>
