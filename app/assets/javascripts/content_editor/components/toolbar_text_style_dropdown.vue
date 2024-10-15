<script>
import { GlTooltipDirective as GlTooltip, GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';
import { TEXT_STYLE_DROPDOWN_ITEMS } from '../constants';
import EditorStateObserver from './editor_state_observer.vue';

export default {
  components: {
    GlCollapsibleListbox,
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
    listboxItems() {
      return this.$options.items.map((item) => {
        return {
          value: item.label,
          text: item.label,
        };
      });
    },
  },
  methods: {
    mapDropdownItemToCommand(dropdownItem) {
      return this.$options.items.find((option) => option.label === dropdownItem);
    },
    updateActiveItem({ editor }) {
      this.activeItem = TEXT_STYLE_DROPDOWN_ITEMS.find((item) =>
        editor.isActive(item.contentType, item.commandParams),
      );
    },
    execute(item) {
      const { editorCommand, contentType, commandParams } = this.mapDropdownItemToCommand(item);
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
    isActive(dropdownItem) {
      return this.tiptapEditor.isActive(dropdownItem.contentType, dropdownItem.commandParams);
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
    <gl-collapsible-listbox
      v-gl-tooltip.hover="$options.i18n.placeholder"
      :items="listboxItems"
      :toggle-text="activeItemLabel"
      :selected="activeItemLabel"
      :disabled="!activeItem"
      :data-qa-text-style="activeItemLabel"
      size="small"
      toggle-class="btn-default-tertiary"
      @select="execute"
    />
  </editor-state-observer>
</template>
