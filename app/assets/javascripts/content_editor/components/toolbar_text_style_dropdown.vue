<script>
import { GlDropdown, GlDropdownItem, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';
import { TEXT_STYLE_DROPDOWN_ITEMS } from '../constants';
import EditorStateObserver from './editor_state_observer.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    EditorStateObserver,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor'],
  data() {
    return {
      activeItem: null,
    };
  },
  computed: {
    activeItemLabel() {
      const { activeItem } = this;

      return activeItem ? activeItem.label : this.$options.i18n.placeholder;
    },
  },
  methods: {
    updateActiveItem({ editor }) {
      this.activeItem = TEXT_STYLE_DROPDOWN_ITEMS.find((item) =>
        editor.isActive(item.contentType, item.commandParams),
      );
    },
    execute(item) {
      const { editorCommand, contentType, commandParams } = item;
      const value = commandParams?.level;

      if (editorCommand) {
        this.tiptapEditor
          .chain()
          [editorCommand](commandParams || {})
          .focus()
          .run();
      }

      this.$emit('execute', { contentType, value });
    },
    isActive(item) {
      return this.tiptapEditor.isActive(item.contentType, item.commandParams);
    },
  },
  items: TEXT_STYLE_DROPDOWN_ITEMS,
  i18n: {
    placeholder: __('Text style'),
  },
};
</script>
<template>
  <editor-state-observer @transaction="updateActiveItem">
    <gl-dropdown
      v-gl-tooltip="$options.i18n.placeholder"
      size="small"
      data-qa-selector="text_style_dropdown"
      :disabled="!activeItem"
      :text="activeItemLabel"
    >
      <gl-dropdown-item
        v-for="(item, index) in $options.items"
        :key="index"
        is-check-item
        :is-checked="isActive(item)"
        data-qa-selector="text_style_menu_item"
        :data-qa-text-style="item.label"
        @click="execute(item)"
      >
        {{ item.label }}
      </gl-dropdown-item>
    </gl-dropdown>
  </editor-state-observer>
</template>
