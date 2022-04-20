<script>
import {
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { BubbleMenu } from '@tiptap/vue-2';
import codeBlockLanguageLoader from '../services/code_block_language_loader';
import CodeBlockHighlight from '../extensions/code_block_highlight';
import Diagram from '../extensions/diagram';
import Frontmatter from '../extensions/frontmatter';
import EditorStateObserver from './editor_state_observer.vue';

const CODE_BLOCK_NODE_TYPES = [CodeBlockHighlight.name, Diagram.name, Frontmatter.name];

export default {
  components: {
    BubbleMenu,
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
    EditorStateObserver,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor'],
  data() {
    return {
      selectedLanguage: {},
      filterTerm: '',
      filteredLanguages: [],
    };
  },
  watch: {
    filterTerm: {
      handler(val) {
        this.filteredLanguages = codeBlockLanguageLoader.filterLanguages(val);
      },
      immediate: true,
    },
  },
  methods: {
    shouldShow: ({ editor }) => {
      return CODE_BLOCK_NODE_TYPES.some((type) => editor.isActive(type));
    },

    getSelectedLanguage() {
      const { language } = this.tiptapEditor.getAttributes(this.getCodeBlockType());

      this.selectedLanguage = codeBlockLanguageLoader.findLanguageBySyntax(language);
    },

    async setSelectedLanguage(language) {
      this.selectedLanguage = language;

      await codeBlockLanguageLoader.loadLanguages([language.syntax]);

      this.tiptapEditor.commands.setCodeBlock({ language: this.selectedLanguage.syntax });
    },

    tippyOnBeforeUpdate(tippy, props) {
      if (props.getReferenceClientRect) {
        // eslint-disable-next-line no-param-reassign
        props.getReferenceClientRect = () => {
          const { view } = this.tiptapEditor;
          const { from } = this.tiptapEditor.state.selection;

          for (let { node } = view.domAtPos(from); node; node = node.parentElement) {
            if (node.nodeName?.toLowerCase() === 'pre') {
              return node.getBoundingClientRect();
            }
          }

          return new DOMRect(-1000, -1000, 0, 0);
        };
      }
    },

    deleteCodeBlock() {
      this.tiptapEditor.chain().focus().deleteNode(this.getCodeBlockType()).run();
    },

    getCodeBlockType() {
      return (
        CODE_BLOCK_NODE_TYPES.find((type) => this.tiptapEditor.isActive(type)) ||
        CodeBlockHighlight.name
      );
    },
  },
};
</script>
<template>
  <bubble-menu
    data-testid="code-block-bubble-menu"
    class="gl-shadow gl-rounded-base"
    :editor="tiptapEditor"
    plugin-key="bubbleMenuCodeBlock"
    :should-show="shouldShow"
    :tippy-options="{ onBeforeUpdate: tippyOnBeforeUpdate }"
  >
    <editor-state-observer @transaction="getSelectedLanguage">
      <gl-button-group>
        <gl-dropdown contenteditable="false" boundary="viewport" :text="selectedLanguage.label">
          <template #header>
            <gl-search-box-by-type
              v-model="filterTerm"
              :clear-button-title="__('Clear')"
              :placeholder="__('Search')"
            />
          </template>

          <template #highlighted-items>
            <gl-dropdown-item :key="selectedLanguage.syntax" is-check-item :is-checked="true">
              {{ selectedLanguage.label }}
            </gl-dropdown-item>
          </template>

          <gl-dropdown-item
            v-for="language in filteredLanguages"
            v-show="selectedLanguage.syntax !== language.syntax"
            :key="language.syntax"
            @click="setSelectedLanguage(language)"
          >
            {{ language.label }}
          </gl-dropdown-item>
        </gl-dropdown>
        <gl-button
          v-gl-tooltip
          variant="default"
          category="primary"
          size="medium"
          :aria-label="__('Delete code block')"
          :title="__('Delete code block')"
          icon="remove"
          @click="deleteCodeBlock"
        />
      </gl-button-group>
    </editor-state-observer>
  </bubble-menu>
</template>
