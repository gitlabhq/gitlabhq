<script>
import {
  GlFormInput,
  GlCollapsibleListbox,
  GlButton,
  GlFormGroup,
  GlForm,
  GlButtonGroup,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { getParentByTagName } from '~/lib/utils/dom_utils';
import codeBlockLanguageLoader from '../../services/code_block_language_loader';
import CodeBlockHighlight from '../../extensions/code_block_highlight';
import Diagram from '../../extensions/diagram';
import Frontmatter from '../../extensions/frontmatter';
import EditorStateObserver from '../editor_state_observer.vue';
import BubbleMenu from './bubble_menu.vue';

const CODE_BLOCK_NODE_TYPES = [CodeBlockHighlight.name, Diagram.name, Frontmatter.name];

export default {
  components: {
    BubbleMenu,
    GlCollapsibleListbox,
    GlFormInput,
    GlFormGroup,
    GlForm,
    GlButton,
    GlButtonGroup,
    EditorStateObserver,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor', 'contentEditor'],
  data() {
    return {
      codeBlockType: undefined,
      filterTerm: '',
      filteredLanguages: [],

      showCustomLanguageInput: false,
      customLanguageType: '',

      selectedLanguage: {},
      isDiagram: false,
      showPreview: false,
    };
  },
  computed: {
    languageItems() {
      const selectedSyntax = this.selectedLanguage?.syntax;
      const initialItem = selectedSyntax
        ? [
            {
              text: this.selectedLanguage.label,
              value: this.selectedLanguage.syntax,
            },
          ]
        : [];
      return this.filteredLanguages.reduce((acc, lang) => {
        if (lang.syntax !== selectedSyntax) {
          acc.push({
            text: lang.label,
            value: lang.syntax,
          });
        }
        return acc;
      }, initialItem);
    },
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

    async updateCodeBlockInfoToState() {
      this.codeBlockType = CODE_BLOCK_NODE_TYPES.find((type) => this.tiptapEditor.isActive(type));

      if (!this.codeBlockType) return;

      const { language, isDiagram, showPreview } = this.tiptapEditor.getAttributes(
        this.codeBlockType,
      );
      this.selectedLanguage = codeBlockLanguageLoader.findOrCreateLanguageBySyntax(
        language,
        isDiagram,
      );
      this.isDiagram = isDiagram;
      this.showPreview = showPreview;
    },

    getCodeBlockText() {
      const { view } = this.tiptapEditor;
      const { from } = this.tiptapEditor.state.selection;
      const node = getParentByTagName(view.domAtPos(from).node, 'pre');
      return node?.textContent || '';
    },

    copyCodeBlockText() {
      // eslint-disable-next-line no-restricted-properties
      navigator.clipboard.writeText(this.getCodeBlockText());
    },

    togglePreview() {
      this.showPreview = !this.showPreview;
      this.tiptapEditor.commands.updateAttributes(Diagram.name, { showPreview: this.showPreview });
    },

    handleCreateCustomTypeClick() {
      this.showCustomLanguageInput = true;
    },

    async applyCustomLanguage() {
      if (!this.customLanguageType.trim()) return;

      const language = codeBlockLanguageLoader.findOrCreateLanguageBySyntax(
        this.customLanguageType.trim(),
      );
      await this.applyLanguage(language);
      this.clearCustomLanguageForm();
    },

    clearCustomLanguageForm() {
      this.showCustomLanguageInput = false;
      this.customLanguageType = '';
    },

    async applyLanguage(language) {
      if (!language || !language.syntax) return;

      this.selectedLanguage = language;

      await codeBlockLanguageLoader.loadLanguage(language.syntax);

      this.tiptapEditor.commands.setCodeBlock({ language: language.syntax });
    },

    handleLanguageSelect(syntax) {
      const language = codeBlockLanguageLoader.findOrCreateLanguageBySyntax(syntax);
      this.applyLanguage(language);
    },

    getReferenceClientRect() {
      const { view } = this.tiptapEditor;
      const { from } = this.tiptapEditor.state.selection;
      const node = getParentByTagName(view.domAtPos(from).node, 'pre');
      return node?.getBoundingClientRect() || new DOMRect(-1000, -1000, 0, 0);
    },

    deleteCodeBlock() {
      this.tiptapEditor.chain().focus().deleteNode(this.codeBlockType).run();
    },

    tippyOptions() {
      return { getReferenceClientRect: this.getReferenceClientRect.bind(this) };
    },
    onBubbleMenuHidden() {
      this.clearCustomLanguageForm();
      this.filterTerm = '';
    },
  },
};
</script>

<template>
  <bubble-menu
    data-testid="code-block-bubble-menu"
    class="gl-rounded-lg gl-bg-overlap gl-shadow"
    plugin-key="bubbleMenuCodeBlock"
    :should-show="shouldShow"
    :tippy-options="tippyOptions()"
    @hidden="onBubbleMenuHidden"
  >
    <gl-form
      v-if="showCustomLanguageInput"
      class="bubble-menu-form gl-border gl-bottom-8 gl-left-0 gl-w-full gl-border-gray-100 gl-p-4"
      @submit.prevent="applyCustomLanguage"
    >
      <gl-form-group :label="__('Create custom type')" label-for="custom-language-type-input">
        <gl-form-input
          id="custom-language-type-input"
          v-model="customLanguageType"
          class="gl-my-4"
          :placeholder="__('Language type')"
          autofocus
        />
      </gl-form-group>
      <div class="gl-flex gl-justify-end">
        <gl-button class="gl-mr-2" variant="default" @click="clearCustomLanguageForm">
          {{ __('Cancel') }}
        </gl-button>
        <gl-button variant="confirm" type="submit" :disabled="!customLanguageType.trim()">
          {{ __('Apply') }}
        </gl-button>
      </div>
    </gl-form>
    <editor-state-observer @transaction="updateCodeBlockInfoToState">
      <gl-button-group>
        <gl-collapsible-listbox
          category="primary"
          :items="languageItems"
          :header-text="__('Select language')"
          :selected="selectedLanguage.syntax"
          :toggle-text="selectedLanguage.label || __('Select language')"
          searchable
          block
          @search="filterTerm = $event"
          @select="handleLanguageSelect"
        >
          <template #footer>
            <div class="gl-border-t gl-p-2">
              <gl-button
                block
                category="tertiary"
                data-testid="create-custom-type"
                @click="handleCreateCustomTypeClick"
              >
                {{ __('Create custom type') }}
              </gl-button>
            </div>
          </template>
        </gl-collapsible-listbox>

        <gl-button
          v-gl-tooltip
          size="medium"
          data-testid="copy-code-block"
          :aria-label="__('Copy code')"
          :title="__('Copy code')"
          icon="copy-to-clipboard"
          @click="copyCodeBlockText"
        />
        <gl-button
          v-if="isDiagram"
          v-gl-tooltip
          size="medium"
          :class="{ '!gl-bg-gray-100': showPreview }"
          data-testid="preview-diagram"
          :aria-label="__('Preview diagram')"
          :title="__('Preview diagram')"
          icon="eye"
          @click="togglePreview"
        />
        <gl-button
          v-gl-tooltip
          size="medium"
          data-testid="delete-code-block"
          :aria-label="__('Delete code block')"
          :title="__('Delete code block')"
          icon="remove"
          @click="deleteCodeBlock"
        />
      </gl-button-group>
    </editor-state-observer>
  </bubble-menu>
</template>
