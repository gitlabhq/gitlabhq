<script>
import _ from 'underscore';
import { mapGetters, mapActions } from 'vuex';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import { pluralize } from '~/lib/utils/text_utility';
import { getParameterValues, mergeUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

export default {
  components: {
    Icon,
    ClipboardButton,
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
    whitespaceVisible() {
      return !getParameterValues('w')[0];
    },
    toggleWhitespaceText() {
      if (this.whitespaceVisible) {
        return __('Hide whitespace changes');
      }
      return __('Show whitespace changes');
    },
    toggleWhitespacePath() {
      if (this.whitespaceVisible) {
        return mergeUrlParams({w: 1}, window.location.href);
      }
      return mergeUrlParams({w: 0}, window.location.href);
    },
  },
  mounted() {
    this.throttledHandleScroll = _.throttle(this.handleScroll, 100);
    document.addEventListener('scroll', this.throttledHandleScroll);
  },
  beforeDestroy() {
    document.removeEventListener('scroll', this.throttledHandleScroll);
  },
  methods: {
    ...mapActions(['setInlineDiffViewType', 'setParallelDiffViewType']),
    pluralize,
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

      if (path.length > maxLength) {
        const start = path.length - maxLength;
        const end = start + maxLength;
        return `...${path.slice(start, end)}`;
      }

      return path;
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
          :href="toggleWhitespacePath"
        >
          {{ toggleWhitespaceText }}
        </a>
        <div class="btn-group">
          <button
            type="button"
            @click="setInlineDiffViewType"
            :class="{ active: isInlineView }"
            id="inline-diff-btn"
            class="btn"
            data-view-type="inline"
          >
            {{ __('Inline') }}
          </button>
          <button
            type="button"
            @click="setParallelDiffViewType"
            :class="{ active: isParallelView }"
            id="parallel-diff-btn"
            class="btn"
            data-view-type="parallel"
          >
            {{ __('Side-by-side') }}
          </button>
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
            {{ pluralize(`${diffFiles.length} changed file`, diffFiles.length) }}
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
            {{ pluralize(`${sumAddedLines} addition`, sumAddedLines) }}
          </strong>
          and
          <strong class="cred">
            {{ pluralize(`${sumRemovedLines} deletion`, sumRemovedLines) }}
          </strong>
        </span>

        <span
          v-show="activeFile"
          class="prepend-left-5"
        >
          <strong class="prepend-right-5">
            {{ truncatedDiffPath(activeFile) }}
          </strong>
          <clipboard-button
            :text="activeFile"
            :title="s__('Copy file name to clipboard')"
            tooltip-placement="bottom"
            tooltip-container="body"
            class="btn btn-default btn-transparent btn-clipboard"
          />
        </span>
      </div>
    </div>
  </div>
</template>
