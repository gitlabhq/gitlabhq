<script>
import { mapGetters, mapActions } from 'vuex';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import { pluralize } from '~/lib/utils/text_utility';
import { getParameterValues, mergeUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import bp from '~/breakpoints';
import ChangedFilesDropdown from './changed_files_dropdown.vue';

export default {
  components: {
    Icon,
    ChangedFilesDropdown,
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
      isStuck: false,
      maxWidth: 'auto',
      top: 0,
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
        return mergeUrlParams({ w: 1 }, window.location.href);
      }

      return mergeUrlParams({ w: 0 }, window.location.href);
    },
  },
  mounted() {
    document.addEventListener('scroll', this.handleScroll);

    this.offsetTop = parseInt(
      window.getComputedStyle(this.$refs.wrapper).getPropertyValue('top'),
      10,
    );
  },
  beforeDestroy() {
    document.removeEventListener('scroll', this.handleScroll);
  },
  methods: {
    ...mapActions(['setInlineDiffViewType', 'setParallelDiffViewType']),
    pluralize,
    handleScroll() {
      if (!this.updating) {
        requestAnimationFrame(this.updateIsStuck);
        this.updating = true;
      }
    },
    updateIsStuck() {
      if (!this.$refs.wrapper) {
        return;
      }

      const wrapperBottom = this.$refs.wrapper.getBoundingClientRect().bottom;
      const scrollPosition = window.scrollY;

      this.isStuck = scrollPosition >= this.$refs.wrapper.offsetTop - this.offsetTop;
      this.updating = false;
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
    ref="wrapper"
    :class="{'is-stuck': isStuck}"
    class="content-block oneline-block diff-files-changed diff-files-changed-merge-request
    files-changed js-diff-files-changed"
  >
    <div class="files-changed-inner">
      <div
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
        <changed-files-dropdown
          :diff-files="diffFiles"
        />

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
      </div>
    </div>
  </div>
</template>
