<script>
import {
  GlTooltipDirective as GlTooltip,
  GlCollapsibleListbox,
  GlButton,
  GlIcon,
} from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { TEXT_STYLE_DROPDOWN_ITEMS } from '../constants';
import EditorStateObserver from './editor_state_observer.vue';

export default {
  components: {
    GlCollapsibleListbox,
    EditorStateObserver,
    GlButton,
    GlIcon,
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
    placeholder: s__('ContentEditor|Text style'),
    ariaLabel: (active) => sprintf(s__('ContentEditor|Text style %{active}'), { active }),
  },
};
</script>
<template>
  <editor-state-observer @transaction="updateActiveItem">
    <gl-collapsible-listbox
      :header-text="$options.i18n.placeholder"
      :items="listboxItems"
      :toggle-text="activeItemLabel"
      :selected="activeItemLabel"
      :disabled="!activeItem"
      :data-qa-text-style="activeItemLabel"
      @select="execute"
    >
      <template #toggle>
        <gl-button
          v-gl-tooltip="$options.i18n.placeholder"
          size="small"
          category="tertiary"
          variant="default"
          :aria-label="$options.i18n.ariaLabel(activeItemLabel)"
          :title="$options.i18n.placeholder"
          class="gl-w-full"
          button-text-classes="gl-mr-[-2px] !gl-flex !gl-justify-between gl-w-full"
          ><span class="gl-flex-grow-1 gl-text-left">{{ activeItemLabel }}</span>
          <gl-icon
            aria-hidden="true"
            name="chevron-down"
            :size="16"
            variant="current"
            class="gl-ml-2 gl-flex-shrink-0"
        /></gl-button>
      </template>
    </gl-collapsible-listbox>
  </editor-state-observer>
</template>
