<script>
import { mapGetters, mapActions } from 'vuex';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import { pluralize } from '~/lib/utils/text_utility';
import { getParameterValues, mergeUrlParams } from '~/lib/utils/url_utility';
import { contentTop } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import ChangedFilesDropdown from './changed_files_dropdown.vue';
import changedFilesMixin from '../mixins/changed_files';

export default {
  components: {
    Icon,
    ChangedFilesDropdown,
    ClipboardButton,
  },
  mixins: [changedFilesMixin],
  data() {
    return {
      isStuck: false,
      maxWidth: 'auto',
      offsetTop: 0,
    };
  },
  computed: {
    ...mapGetters('diffs', ['isInlineView', 'isParallelView', 'areAllFilesCollapsed']),
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
    top() {
      return `${this.offsetTop}px`;
    },
  },
  created() {
    document.addEventListener('scroll', this.handleScroll);
    this.offsetTop = contentTop();
  },
  beforeDestroy() {
    document.removeEventListener('scroll', this.handleScroll);
  },
  methods: {
    ...mapActions('diffs', ['setInlineDiffViewType', 'setParallelDiffViewType', 'expandAllFiles']),
    pluralize,
    handleScroll() {
      if (!this.updating) {
        this.$nextTick(this.updateIsStuck);
        this.updating = true;
      }
    },
    updateIsStuck() {
      if (!this.$refs.wrapper) {
        return;
      }

      const scrollPosition = window.scrollY;

      this.isStuck = scrollPosition + this.offsetTop >= this.$refs.placeholder.offsetTop;
      this.updating = false;
    },
    sumValues(key) {
      return this.diffFiles.reduce((total, file) => total + file[key], 0);
    },
  },
};
</script>

<template>
  <span>
    <div ref="placeholder"></div>
    <div
      ref="wrapper"
      :style="{ top }"
      :class="{'is-stuck': isStuck}"
      class="content-block oneline-block diff-files-changed diff-files-changed-merge-request
      files-changed js-diff-files-changed"
    >
      <div class="files-changed-inner">
        <div
          class="inline-parallel-buttons d-none d-md-block"
        >
          <a
            v-if="areAllFilesCollapsed"
            class="btn btn-default"
            @click="expandAllFiles"
          >
            {{ __('Expand all') }}
          </a>
          <a
            :href="toggleWhitespacePath"
            class="btn btn-default"
          >
            {{ toggleWhitespaceText }}
          </a>
          <div class="btn-group">
            <button
              id="inline-diff-btn"
              :class="{ active: isInlineView }"
              type="button"
              class="btn js-inline-diff-button"
              data-view-type="inline"
              @click="setInlineDiffViewType"
            >
              {{ __('Inline') }}
            </button>
            <button
              id="parallel-diff-btn"
              :class="{ active: isParallelView }"
              type="button"
              class="btn js-parallel-diff-button"
              data-view-type="parallel"
              @click="setParallelDiffViewType"
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
            class="js-diff-stats-additions-deletions-expanded
            diff-stats-additions-deletions-expanded"
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
          <div
            class="js-diff-stats-additions-deletions-collapsed
            diff-stats-additions-deletions-collapsed float-right d-sm-none"
          >
            <strong class="cgreen">
              +{{ sumAddedLines }}
            </strong>
            <strong class="cred">
              -{{ sumRemovedLines }}
            </strong>
          </div>
        </div>
      </div>
    </div>
  </span>
</template>
