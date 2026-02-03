<script>
import { mapState, mapActions } from 'pinia';
import { GlButton } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import FileBrowserHeight from '~/diffs/components/file_browser_height.vue';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
import { useMainContainer } from '~/pinia/global_stores/main_container';
import TreeList from './components/tree_list.vue';

export const TREE_WIDTH = 320;
export const MIN_TREE_WIDTH = 240;
export const FILE_TREE_BROWSER_STORAGE_KEY = 'file_tree_browser_storage_key';

export default {
  name: 'FileTreeBrowser',
  components: {
    TreeList,
    FileBrowserHeight,
    PanelResizer,
    GlButton,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    currentRef: {
      type: String,
      required: true,
    },
    refType: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      treeWidth: TREE_WIDTH,
      isAnimating: false,
    };
  },
  computed: {
    ...mapState(useFileTreeBrowserVisibility, [
      'fileTreeBrowserIsExpanded',
      'fileTreeBrowserIsPeekOn',
      'fileTreeBrowserIsVisible',
    ]),
    ...mapState(useMainContainer, ['isCompact']),
    visibilityClasses() {
      return {
        'file-tree-browser-expanded gl-sticky gl-pb-5': this.fileTreeBrowserIsExpanded,
        'file-tree-browser-peek gl-left-0 gl-pb-9': this.fileTreeBrowserIsPeekOn,
      };
    },
  },
  created() {
    this.restoreTreeWidthUserPreference();
  },
  mounted() {
    document.addEventListener('keydown', this.handleEscapeKey);
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.handleEscapeKey);
  },
  methods: {
    ...mapActions(useFileTreeBrowserVisibility, ['resetFileTreeBrowserAllStates']),
    restoreTreeWidthUserPreference() {
      const userPreference = localStorage.getItem(FILE_TREE_BROWSER_STORAGE_KEY);
      if (!userPreference) return;
      this.treeWidth = parseInt(userPreference, 10);
    },
    onSizeUpdate(value) {
      this.treeWidth = value;
    },
    saveTreeWidthPreference(size) {
      localStorage.setItem(FILE_TREE_BROWSER_STORAGE_KEY, size);
      this.treeWidth = size;
    },
    onOverlayClick() {
      this.resetFileTreeBrowserAllStates();
    },
    handleEscapeKey(event) {
      if (event.key === 'Escape' && this.fileTreeBrowserIsPeekOn) {
        this.resetFileTreeBrowserAllStates();
      }
    },
  },
  fileTreeBrowserStorageKey: FILE_TREE_BROWSER_STORAGE_KEY,
  minTreeWidth: MIN_TREE_WIDTH,
  maxTreeWidth: 500,
  feedbackIssue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/581271',
};
</script>

<template>
  <div class="gl-relative">
    <div
      v-if="fileTreeBrowserIsPeekOn"
      class="file-tree-browser-overlay gl-fixed gl-bottom-0 gl-left-0 gl-right-0 gl-top-0"
      data-testid="overlay"
      @click="onOverlayClick"
    ></div>
    <transition
      name="file-tree-browser-slide"
      @before-leave="isAnimating = true"
      @after-leave="isAnimating = false"
    >
      <file-browser-height
        v-show="fileTreeBrowserIsVisible"
        :enable-sticky-height="!isCompact"
        :style="{ '--tree-width': `${treeWidth}px` }"
        class="file-tree-browser file-tree-browser-responsive gl-fixed gl-left-0 gl-flex-none gl-p-4 @md/panel:gl-pl-0"
        :class="visibilityClasses"
      >
        <panel-resizer
          class="max-@md/panel:gl-hidden"
          :start-size="treeWidth"
          :min-size="$options.minTreeWidth"
          :max-size="$options.maxTreeWidth"
          side="right"
          @update:size="onSizeUpdate"
          @resize-end="saveTreeWidthPreference"
        />
        <tree-list
          :project-path="projectPath"
          :current-ref="currentRef"
          :ref-type="refType"
          :is-animating="isAnimating"
        />
        <gl-button
          target="_blank"
          icon="comment-dots"
          rel="noopener noreferrer"
          :href="$options.feedbackIssue"
          >{{ __('Provide feedback') }}</gl-button
        >
      </file-browser-height>
    </transition>
  </div>
</template>
