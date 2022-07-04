<script>
import { GlButtonGroup } from '@gitlab/ui';
import { BubbleMenu } from '@tiptap/vue-2';
import { BUBBLE_MENU_TRACKING_ACTION } from '../../constants';
import trackUIControl from '../../services/track_ui_control';
import Image from '../../extensions/image';
import Audio from '../../extensions/audio';
import Video from '../../extensions/video';
import Code from '../../extensions/code';
import CodeBlockHighlight from '../../extensions/code_block_highlight';
import Diagram from '../../extensions/diagram';
import Frontmatter from '../../extensions/frontmatter';
import ToolbarButton from '../toolbar_button.vue';

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

    shouldShow: ({ editor, from, to }) => {
      if (from === to) return false;

      const exclude = [
        Code.name,
        CodeBlockHighlight.name,
        Diagram.name,
        Frontmatter.name,
        Image.name,
        Audio.name,
        Video.name,
      ];

      return !exclude.some((type) => editor.isActive(type));
    },
  },
};
</script>
<template>
  <bubble-menu
    data-testid="formatting-bubble-menu"
    class="gl-shadow gl-rounded-base gl-bg-white"
    :editor="tiptapEditor"
    :should-show="shouldShow"
  >
    <gl-button-group>
      <toolbar-button
        data-testid="bold"
        content-type="bold"
        icon-name="bold"
        editor-command="toggleBold"
        category="tertiary"
        size="medium"
        :label="__('Bold text')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="italic"
        content-type="italic"
        icon-name="italic"
        editor-command="toggleItalic"
        category="tertiary"
        size="medium"
        :label="__('Italic text')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="strike"
        content-type="strike"
        icon-name="strikethrough"
        editor-command="toggleStrike"
        category="tertiary"
        size="medium"
        :label="__('Strikethrough')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="code"
        content-type="code"
        icon-name="code"
        editor-command="toggleCode"
        category="tertiary"
        size="medium"
        :label="__('Code')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="link"
        content-type="link"
        icon-name="link"
        editor-command="toggleLink"
        :editor-command-params="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
          href: '',
        } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
        category="tertiary"
        size="medium"
        :label="__('Insert link')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="superscript"
        content-type="superscript"
        icon-name="superscript"
        editor-command="toggleSuperscript"
        category="tertiary"
        size="medium"
        :label="__('Superscript')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="subscript"
        content-type="subscript"
        icon-name="subscript"
        editor-command="toggleSubscript"
        category="tertiary"
        size="medium"
        :label="__('Subscript')"
        @execute="trackToolbarControlExecution"
      />
    </gl-button-group>
  </bubble-menu>
</template>
