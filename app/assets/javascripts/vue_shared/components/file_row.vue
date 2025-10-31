<script>
import { GlTruncate, GlIcon, GlTooltipDirective, GlButton } from '@gitlab/ui';
import { escapeFileUrl } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import FileHeader from '~/vue_shared/components/file_row_header.vue';
import { InternalEvents } from '~/tracking';

export default {
  name: 'FileRow',
  components: {
    FileHeader,
    FileIcon,
    GlTruncate,
    GlIcon,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    file: {
      type: Object,
      required: true,
    },
    fileUrl: {
      type: String,
      required: false,
      default: '',
    },
    level: {
      type: Number,
      required: true,
    },
    fileClasses: {
      type: String,
      required: false,
      default: '',
    },
    truncateMiddle: {
      type: Boolean,
      required: false,
      default: false,
    },
    showTreeToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isTree() {
      return this.file.type === 'tree';
    },
    isBlob() {
      return this.file.type === 'blob';
    },
    fileClass() {
      const addFilePadding = !this.isTree && this.showTreeToggle;
      return {
        'file-open': this.isBlob && this.file.opened,
        'is-active': this.isBlob && this.file.active,
        folder: this.isTree,
        'is-open': this.file.opened,
        'is-linked': this.file.linked,
        'pl-3': addFilePadding,
      };
    },
    textForTitle() {
      // don't output a title if we don't have the expanded path
      return this.file?.tree?.length ? this.file.tree[0].parentPath : false;
    },
    fileRouterUrl() {
      return this.fileUrl || `/project${this.file.url}`;
    },
    chevronIcon() {
      return this.file.opened ? 'chevron-down' : 'chevron-right';
    },
    chevronAriaLabel() {
      const action = this.file.opened
        ? __('Collapse %{name} directory')
        : __('Expand %{name} directory');
      return sprintf(action, { name: this.file.name });
    },
  },
  watch: {
    'file.active': function fileActiveWatch(active) {
      if (this.file.type === 'blob' && active) {
        this.scrollIntoView();
      }
    },
  },
  mounted() {
    if (this.hasPathAtCurrentRoute()) {
      this.scrollIntoView(true);
    }
  },
  methods: {
    toggleTreeOpen(path) {
      this.$emit('toggleTreeOpen', path);
    },
    onChevronClick(event) {
      event.stopPropagation();
      this.$emit('clickTree');
    },
    clickFile() {
      this.trackEvent('click_file_tree_browser_on_repository_page');

      // Manual Action if a tree is selected/opened
      if (this.isTree) this.$emit('clickTree', { toggleClose: false });
      if (this.isTree && this.hasUrlAtCurrentRoute()) {
        this.toggleTreeOpen(this.file.path);
      }

      if (this.$router && !this.hasUrlAtCurrentRoute()) this.$router.push(this.fileRouterUrl);

      if (this.isBlob) this.$emit('clickFile', this.file);
    },
    scrollIntoView(isInit = false) {
      const block = isInit && this.isTree ? 'center' : 'nearest';

      this.$el.scrollIntoView({
        behavior: 'smooth',
        block,
      });
    },
    hasPathAtCurrentRoute() {
      if (!this.$router || !this.$router.currentRoute || this.file.isShowMore) {
        return false;
      }

      // - strip route up to "/-/" and ending "/"
      const routePath = this.$router.currentRoute.path
        .replace(/^.*?[/]-[/]/g, '')
        .replace(/[/]$/g, '');

      // - strip ending "/"
      const filePath = this.file.path.replace(/[/]$/g, '');

      return filePath === routePath;
    },
    hasUrlAtCurrentRoute() {
      if (!this.$router || !this.$router.currentRoute) return true;

      return escapeFileUrl(this.$router.currentRoute.path) === escapeFileUrl(this.fileRouterUrl);
    },
  },
};
</script>

<template>
  <file-header v-if="file.isHeader" :path="file.path" />
  <gl-button
    v-else-if="file.isShowMore"
    category="tertiary"
    :loading="file.loading"
    class="!gl-border-none !gl-pl-6"
    button-text-classes="gl-text-blue-700"
    @click="$emit('showMore')"
  >
    {{ __('Show more') }}
  </gl-button>

  <div v-else class="gl-flex gl-items-center">
    <gl-button
      v-if="isTree && showTreeToggle"
      category="tertiary"
      size="small"
      :icon="chevronIcon"
      data-testid="tree-toggle-button"
      class="file-row-indentation gl-mr-1 gl-shrink-0"
      :aria-label="chevronAriaLabel"
      @click="onChevronClick"
    />

    <button
      :class="fileClass"
      :title="textForTitle"
      :data-level="level"
      class="file-row gl-flex-grow-1"
      :data-file-row="file.fileHash"
      data-testid="file-row"
      :aria-expanded="file.type === 'tree' ? file.opened.toString() : undefined"
      :aria-label="file.name"
      @click="clickFile"
    >
      <span
        ref="textOutput"
        class="file-row-name"
        :title="file.name"
        :data-qa-file-name="file.name"
        data-testid="file-row-name-container"
        :class="[
          fileClasses,
          {
            'str-truncated': !truncateMiddle,
            'gl-min-w-0': truncateMiddle,
            'file-row-indentation': !(isTree && showTreeToggle),
          },
        ]"
      >
        <gl-icon
          v-if="file.linked"
          v-gl-tooltip="
            __('This file was linked in the page URL and will appear as the first one in the list')
          "
          name="link"
          :size="16"
        />
        <file-icon
          class="gl-mr-2"
          :class="{ 'gl-text-subtle': file.type === 'tree' }"
          :file-name="file.name"
          :loading="file.loading"
          :folder="isTree"
          :opened="file.opened"
          :size="16"
          :submodule="file.submodule"
        />
        <gl-truncate
          v-if="truncateMiddle"
          :text="file.name"
          position="middle"
          class="gl-items-center gl-pr-7"
        />
        <template v-else>{{ file.name }}</template>
      </span>
      <slot></slot>
    </button>
  </div>
</template>

<style>
.file-row {
  display: flex;
  align-items: center;
  height: var(--file-row-height, 32px);
  padding: 4px 8px;
  margin-left: -8px;
  margin-right: -8px;
  border-radius: 3px;
  text-align: left;
  cursor: pointer;
  color: unset;
}

.file-row-name-container {
  display: flex;
  width: 100%;
  align-items: center;
  overflow: visible;
}

.file-row-indentation {
  margin-left: calc(var(--level) * var(--file-row-level-padding, 16px));
}

.file-row-name {
  display: flex;
  align-items: center;
  flex: 1;
  max-width: inherit;
  line-height: 1rem;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
