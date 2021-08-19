<script>
import { GlButtonGroup } from '@gitlab/ui';
import { BubbleMenu } from '@tiptap/vue-2';
import { BUBBLE_MENU_TRACKING_ACTION } from '../constants';
import trackUIControl from '../services/track_ui_control';
import ToolbarButton from './toolbar_button.vue';

export default {
  components: {
    BubbleMenu,
    GlButtonGroup,
    ToolbarButton,
  },
  inject: ['tiptapEditor'],
  methods: {
    trackToolbarControlExecution({ contentType, value }) {
      trackUIControl({ action: BUBBLE_MENU_TRACKING_ACTION, property: contentType, value });
    },
  },
};
</script>
<template>
  <bubble-menu class="gl-shadow gl-rounded-base" :editor="tiptapEditor">
    <gl-button-group>
      <toolbar-button
        data-testid="bold"
        content-type="bold"
        icon-name="bold"
        editor-command="toggleBold"
        category="primary"
        size="medium"
        :label="__('Bold text')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="italic"
        content-type="italic"
        icon-name="italic"
        editor-command="toggleItalic"
        category="primary"
        size="medium"
        :label="__('Italic text')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="strike"
        content-type="strike"
        icon-name="strikethrough"
        editor-command="toggleStrike"
        category="primary"
        size="medium"
        :label="__('Strikethrough')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="code"
        content-type="code"
        icon-name="code"
        editor-command="toggleCode"
        category="primary"
        size="medium"
        :label="__('Code')"
        @execute="trackToolbarControlExecution"
      />
    </gl-button-group>
  </bubble-menu>
</template>
