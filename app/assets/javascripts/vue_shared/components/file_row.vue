<script>
import { GlTruncate, GlIcon, GlTooltipDirective, GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import FileIcon from '~/vue_shared/components/file_icon.vue';

export default {
  name: 'FileRow',
  components: {
    FileIcon,
    GlTruncate,
    GlIcon,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    showTreeToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
    // Should be set to true if parent handles focus management (ARIA treeview pattern)
    rovingTabindex: {
      type: Boolean,
      required: false,
      default: false,
    },
    boldText: {
      type: Boolean,
      required: false,
      default: true,
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
        '!gl-bg-feedback-info': this.file.linked,
        'pl-3': addFilePadding,
      };
    },
    textForTitle() {
      // don't output a title if we don't have the expanded path
      return this.file?.tree?.length ? this.file.tree[0].parentPath : false;
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
    buttonTabindex() {
      return this.rovingTabindex ? -1 : 0;
    },
    fileRowContainerClassList() {
      // Left position: (1.5rem button / 2) - (1px line / 2)
      return { 'before:!gl-left-[calc(0.75rem-0.5px)]': this.showTreeToggle };
    },
  },
  methods: {
    clickFile(event) {
      // allow opening in new tab with ctrl/cmd and click
      // without opening in current tab
      if (this.file.href && (event.ctrlKey || event.metaKey)) {
        return;
      }

      this.$emit('clickRow', event);

      if (this.isTree) {
        this.$emit('clickTree', event);
      } else if (this.file.submodule) {
        this.$emit('clickSubmodule', event);
      } else if (this.isBlob) {
        this.$emit('clickFile', event);
      }

      if (this.file.href) {
        event.preventDefault();
      }
    },
  },
};
</script>

<template>
  <div
    v-if="file.isHeader"
    class="file-row-header sticky-top js-file-row-header gl-bg-default gl-px-2"
    :title="file.path"
  >
    <gl-truncate :text="file.path" position="middle" class="gl-font-bold" />
  </div>
  <gl-button
    v-else-if="file.isShowMore"
    category="tertiary"
    :loading="file.loading"
    class="gl-w-full !gl-justify-start !gl-border-none !gl-pl-6 hover:!gl-bg-transparent"
    button-text-classes="gl-text-blue-700"
    :tabindex="buttonTabindex"
    @click="$emit('showMore', $event)"
  >
    {{ __('Show more') }}
  </gl-button>
  <div
    v-else
    data-testid="file-row-container"
    class="gl-flex gl-items-center"
    :class="fileRowContainerClassList"
    :style="{ '--level': file.level }"
  >
    <gl-button
      v-if="isTree && showTreeToggle"
      category="tertiary"
      size="small"
      :icon="chevronIcon"
      data-testid="tree-toggle-button"
      class="file-row-indentation gl-z-3 gl-mr-1 gl-shrink-0 hover:!gl-bg-transparent"
      :aria-label="chevronAriaLabel"
      :tabindex="buttonTabindex"
      @click="$emit('toggleTree', $event)"
    />

    <component
      :is="file.href ? 'a' : 'button'"
      :href="file.href"
      :class="fileClass"
      :title="textForTitle"
      :data-level="level"
      class="file-row gl-flex-grow-1 hover:gl-text-inherit hover:gl-no-underline"
      :data-file-row="file.fileHash"
      data-testid="file-row"
      :aria-expanded="file.type === 'tree' ? file.opened.toString() : undefined"
      :aria-label="file.name"
      :tabindex="buttonTabindex"
      @click="clickFile"
    >
      <span
        ref="textOutput"
        class="file-row-name gl-min-w-0"
        :title="file.name"
        :data-qa-file-name="file.name"
        data-testid="file-row-name-container"
        :class="{
          'file-row-indentation': !(isTree && showTreeToggle),
          'gl-font-bold': boldText,
        }"
      >
        <gl-icon
          v-if="file.linked"
          v-gl-tooltip.right="
            __('This file was linked in the page URL and will appear as the first one in the list')
          "
          name="link"
          :size="16"
          class="gl-flex-none"
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
          :text="file.name"
          position="middle"
          class="gl-min-w-0 gl-items-center gl-pr-2"
        />
      </span>
      <slot></slot>
    </component>
  </div>
</template>

<style>
.file-row {
  display: flex;
  align-items: center;
  height: var(--file-row-height, 32px);
  padding: 4px 8px;
  margin-left: -8px;
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
