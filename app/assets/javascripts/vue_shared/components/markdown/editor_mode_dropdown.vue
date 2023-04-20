<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    size: {
      type: String,
      required: false,
      default: 'medium',
    },
    value: {
      type: String,
      required: true,
    },
  },
  computed: {
    markdownEditorSelected() {
      return this.value === 'markdown';
    },
    text() {
      return this.markdownEditorSelected ? __('Editing markdown') : __('Editing rich text');
    },
  },
};
</script>
<template>
  <gl-dropdown
    category="tertiary"
    data-qa-selector="editing_mode_switcher"
    :size="size"
    :text="text"
    right
  >
    <gl-dropdown-item
      is-check-item
      :is-checked="!markdownEditorSelected"
      @click="$emit('input', 'richText')"
      ><div class="gl-font-weight-bold">{{ __('Rich text') }}</div>
      <div class="gl-text-secondary">
        {{ __('View the formatted output in real-time as you edit.') }}
      </div>
    </gl-dropdown-item>
    <gl-dropdown-item
      is-check-item
      :is-checked="markdownEditorSelected"
      @click="$emit('input', 'markdown')"
      ><div class="gl-font-weight-bold">{{ __('Markdown') }}</div>
      <div class="gl-text-secondary">
        {{ __('View and edit markdown, with the option to preview the formatted output.') }}
      </div></gl-dropdown-item
    >
  </gl-dropdown>
</template>
