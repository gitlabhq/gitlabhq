<script>
import {
  GlDropdownForm,
  GlFormInput,
  GlDropdownDivider,
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
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
    GlDropdownForm,
    GlFormInput,
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlSearchBoxByType,
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
      navigator.clipboard.writeText(this.getCodeBlockText());
    },

    togglePreview() {
      this.showPreview = !this.showPreview;
      this.tiptapEditor.commands.updateAttributes(Diagram.name, { showPreview: this.showPreview });
    },

    async applyLanguage(language) {
      this.selectedLanguage = language;

      await codeBlockLanguageLoader.loadLanguage(language.syntax);

      this.tiptapEditor.commands.setCodeBlock({ language: this.selectedLanguage.syntax });
    },

    clearCustomLanguageForm() {
      this.showCustomLanguageInput = false;
      this.customLanguageType = '';
    },

    applyCustomLanguage() {
      this.showCustomLanguageInput = false;

      const language = codeBlockLanguageLoader.findOrCreateLanguageBySyntax(
        this.customLanguageType,
      );

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
  },
};
</script>
<template>
  <bubble-menu
    data-testid="code-block-bubble-menu"
    class="gl-rounded-base gl-bg-white gl-shadow"
    plugin-key="bubbleMenuCodeBlock"
    :should-show="shouldShow"
    :tippy-options="tippyOptions()"
  >
    <editor-state-observer @transaction="updateCodeBlockInfoToState">
      <gl-button-group>
        <gl-dropdown
          category="tertiary"
          :contenteditable="false"
          boundary="viewport"
          :text="selectedLanguage.label"
          @hide="clearCustomLanguageForm"
        >
          <template v-if="showCustomLanguageInput" #header>
            <div class="gl-relative">
              <gl-button
                v-gl-tooltip
                class="gl-absolute -gl-mt-3 gl-ml-2"
                variant="default"
                category="tertiary"
                size="medium"
                :aria-label="__('Go back')"
                :title="__('Go back')"
                icon="arrow-left"
                @click.prevent.stop="showCustomLanguageInput = false"
              />
              <p class="gl-dropdown-header-top !gl-mb-0 !gl-border-none !gl-pb-1 gl-text-center">
                {{ __('Create custom type') }}
              </p>
            </div>
          </template>
          <template v-else #header>
            <gl-search-box-by-type
              v-model="filterTerm"
              :clear-button-title="__('Clear')"
              :placeholder="__('Search')"
            />
          </template>

          <template v-if="!showCustomLanguageInput" #highlighted-items>
            <gl-dropdown-item :key="selectedLanguage.syntax" is-check-item is-checked>
              {{ selectedLanguage.label }}
            </gl-dropdown-item>
          </template>

          <template v-if="!showCustomLanguageInput" #default>
            <gl-dropdown-item
              v-for="language in filteredLanguages"
              v-show="selectedLanguage.syntax !== language.syntax"
              :key="language.syntax"
              @click="applyLanguage(language)"
            >
              {{ language.label }}
            </gl-dropdown-item>
          </template>
          <template v-else #default>
            <gl-dropdown-form @submit.prevent="applyCustomLanguage">
              <div class="gl-mx-4 gl-mb-3 gl-mt-2">
                <gl-form-input v-model="customLanguageType" :placeholder="__('Language type')" />
              </div>
              <gl-dropdown-divider />
              <div class="gl-mx-4 gl-mt-3 gl-flex gl-justify-end">
                <gl-button
                  variant="default"
                  size="medium"
                  category="primary"
                  class="gl-mr-2 !gl-w-auto"
                  @click.prevent.stop="showCustomLanguageInput = false"
                >
                  {{ __('Cancel') }}
                </gl-button>
                <gl-button
                  variant="confirm"
                  size="medium"
                  category="primary"
                  type="submit"
                  class="!gl-w-auto"
                >
                  {{ __('Apply') }}
                </gl-button>
              </div>
            </gl-dropdown-form>
          </template>

          <template v-if="!showCustomLanguageInput" #footer>
            <gl-dropdown-item
              data-testid="create-custom-type"
              @click.capture.native.stop="showCustomLanguageInput = true"
            >
              {{ __('Create custom type') }}
            </gl-dropdown-item>
          </template>
        </gl-dropdown>
        <gl-button
          v-gl-tooltip
          variant="default"
          category="tertiary"
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
          variant="default"
          category="tertiary"
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
          variant="default"
          category="tertiary"
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
