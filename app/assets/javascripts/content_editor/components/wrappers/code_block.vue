<script>
import { debounce } from 'lodash';
import { GlButton, GlTooltipDirective as GlTooltip, GlSprintf } from '@gitlab/ui';
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import SandboxedMermaid from '~/behaviors/components/sandboxed_mermaid.vue';
import codeBlockLanguageLoader from '../../services/code_block_language_loader';
import EditorStateObserver from '../editor_state_observer.vue';
import { memoizedGet } from '../../services/utils';
import {
  lineOffsetToLangParams,
  langParamsToLineOffset,
  toAbsoluteLineOffset,
  getLines,
  appendNewlines,
} from '../../services/code_suggestion_utils';

export default {
  name: 'CodeBlock',
  components: {
    GlButton,
    GlSprintf,
    NodeViewWrapper,
    NodeViewContent,
    EditorStateObserver,
    SandboxedMermaid,
  },
  directives: {
    GlTooltip,
  },
  inject: ['contentEditor'],
  props: {
    editor: {
      type: Object,
      required: true,
    },
    node: {
      type: Object,
      required: true,
    },
    updateAttributes: {
      type: Function,
      required: true,
    },
    selected: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      diagramUrl: '',
      diagramSource: '',

      allLines: [],
      deletedLines: [],
      addedLines: [],
    };
  },
  computed: {
    themeClass() {
      return window.gon?.user_color_scheme;
    },
    isCodeSuggestion() {
      return (
        this.node.attrs.isCodeSuggestion &&
        this.contentEditor.codeSuggestionsConfig?.canSuggest &&
        this.contentEditor.codeSuggestionsConfig?.diffFile
      );
    },
    classList() {
      return this.isCodeSuggestion
        ? '!gl-p-0 suggestion-added-input'
        : `gl-p-3 code highlight ${this.$options.userColorScheme}`;
    },
    lineOffset() {
      return langParamsToLineOffset(this.node.attrs.langParams);
    },
    absoluteLineOffset() {
      if (!this.contentEditor.codeSuggestionsConfig) return [0, 0];

      const { new_line: n } = this.contentEditor.codeSuggestionsConfig.line;
      return toAbsoluteLineOffset(this.lineOffset, n);
    },
    disableDecrementLineStart() {
      return this.absoluteLineOffset[0] <= 1;
    },
    disableIncrementLineStart() {
      return this.lineOffset[0] >= 0;
    },
    disableDecrementLineEnd() {
      return this.lineOffset[1] <= 0;
    },
    disableIncrementLineEnd() {
      return this.absoluteLineOffset[1] >= this.allLines.length - 1;
    },
  },
  async mounted() {
    if (this.isCodeSuggestion) {
      await this.updateAllLines();
      this.updateCodeSuggestion();
    }

    this.updateCodeBlock = debounce(this.updateCodeBlock, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);

    const lang = codeBlockLanguageLoader.findOrCreateLanguageBySyntax(this.node.attrs.language);
    await codeBlockLanguageLoader.loadLanguage(lang.syntax);

    this.updateAttributes({ language: this.node.attrs.language });
  },
  methods: {
    async updateAllLines() {
      const { diffFile } = this.contentEditor.codeSuggestionsConfig;
      this.allLines = (await memoizedGet(diffFile.view_path.replace('/blob/', '/raw/'))).split(
        '\n',
      );
    },
    updateCodeSuggestion() {
      this.deletedLines = appendNewlines(getLines(this.absoluteLineOffset, this.allLines));
      this.addedLines = appendNewlines(
        this.$refs.nodeViewContent?.$el.textContent.split('\n') || [],
      );
    },
    updateNodeView() {
      if (this.isCodeSuggestion) {
        this.updateCodeSuggestion();
      } else {
        this.updateCodeBlock();
      }
    },
    async updateCodeBlock() {
      if (!this.node.attrs.showPreview) {
        this.diagramSource = '';
        return;
      }

      if (!this.editor.isActive('diagram')) return;

      this.diagramSource = this.$refs.nodeViewContent?.$el.textContent || '';

      if (this.node.attrs.language !== 'mermaid') {
        this.diagramUrl = await this.contentEditor.renderDiagram(
          this.diagramSource,
          this.node.attrs.language,
        );
      }
    },
    updateLineOffset(deltaStart = 0, deltaEnd = 0) {
      const { lineOffset } = this;

      this.editor
        .chain()
        .updateAttributes('codeSuggestion', {
          langParams: lineOffsetToLangParams([
            lineOffset[0] + deltaStart,
            lineOffset[1] + deltaEnd,
          ]),
        })
        .run();
    },
  },
  userColorScheme: gon.user_color_scheme,
};
</script>
<template>
  <editor-state-observer :debounce="0" @transaction="updateNodeView">
    <node-view-wrapper
      :class="classList"
      class="content-editor-code-block gl-relative"
      as="pre"
      dir="auto"
    >
      <div
        v-if="node.attrs.showPreview"
        :contenteditable="false"
        data-testid="sandbox-preview"
        class="!-gl-ml-4 !-gl-mr-4 !-gl-mt-3 gl-mb-3 gl-border-b-1 gl-border-b-default !gl-bg-white gl-p-4 gl-border-b-solid"
      >
        <sandboxed-mermaid v-if="node.attrs.language === 'mermaid'" :source="diagramSource" />
        <img v-else ref="diagramContainer" :src="diagramUrl" />
      </div>
      <span
        v-if="node.attrs.isFrontmatter"
        :contenteditable="false"
        data-testid="frontmatter-label"
        class="gl-absolute gl-right-3 gl-top-0"
        >{{ __('frontmatter') }}:{{ node.attrs.language }}</span
      >
      <div
        v-if="isCodeSuggestion"
        :contenteditable="false"
        class="gl-relative gl-z-0"
        data-testid="code-suggestion-box"
      >
        <div
          class="md-suggestion-header gl-z-1 gl-w-full gl-flex-wrap !gl-border-b-1 !gl-border-none gl-px-4 gl-py-3 gl-font-regular !gl-border-b-solid"
        >
          <div class="gl-pr-3 gl-font-bold">
            {{ __('Suggested change') }}
          </div>

          <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-2 gl-whitespace-nowrap gl-pl-3">
            <gl-sprintf :message="__('From line %{line1} to %{line2}')">
              <template #line1>
                <div class="gl-mx-1 gl-flex gl-rounded-base gl-bg-strong">
                  <gl-button
                    size="small"
                    icon="dash"
                    variant="confirm"
                    category="tertiary"
                    data-testid="decrement-line-start"
                    :aria-label="__('Decrement suggestion line start')"
                    :disabled="disableDecrementLineStart"
                    @click="updateLineOffset(-1, 0)"
                  />
                  <div class="monospace gl-flex gl-items-center gl-justify-center gl-px-3">
                    <strong>{{ absoluteLineOffset[0] }}</strong>
                  </div>
                  <gl-button
                    size="small"
                    icon="plus"
                    variant="confirm"
                    category="tertiary"
                    data-testid="increment-line-start"
                    :aria-label="__('Increment suggestion line start')"
                    :disabled="disableIncrementLineStart"
                    @click="updateLineOffset(1, 0)"
                  />
                </div>
              </template>
              <template #line2>
                <div class="gl-ml-1 gl-flex gl-rounded-base gl-bg-strong">
                  <gl-button
                    size="small"
                    icon="dash"
                    variant="confirm"
                    category="tertiary"
                    data-testid="decrement-line-end"
                    :aria-label="__('Decrement suggestion line end')"
                    :disabled="disableDecrementLineEnd"
                    @click="updateLineOffset(0, -1)"
                  />
                  <div class="monospace gl-flex gl-items-center gl-justify-center gl-px-3">
                    <strong>{{ absoluteLineOffset[1] }}</strong>
                  </div>
                  <gl-button
                    size="small"
                    icon="plus"
                    variant="confirm"
                    category="tertiary"
                    data-testid="increment-line-end"
                    :aria-label="__('Increment suggestion line end')"
                    :disabled="disableIncrementLineEnd"
                    @click="updateLineOffset(0, 1)"
                  />
                </div>
              </template>
            </gl-sprintf>
          </div>
        </div>

        <div class="suggestion-deleted code" :class="themeClass" data-testid="suggestion-deleted">
          <code
            v-for="(line, i) in deletedLines"
            :key="i"
            :data-line-number="absoluteLineOffset[0] + i"
            class="diff-line-num !gl-border-transparent"
            ><span class="line_holder"
              ><span class="line_content old">{{ line }}</span></span
            ></code
          >
        </div>
        <div
          class="suggestion-added code gl-absolute"
          :class="themeClass"
          data-testid="suggestion-added"
        >
          <code
            v-for="(line, i) in addedLines"
            :key="i"
            :data-line-number="absoluteLineOffset[0] + i"
            class="diff-line-num !gl-border-transparent"
            ><span class="line_holder"
              ><span class="line_content new !gl-text-transparent">{{ line }}</span></span
            ></code
          >
        </div>
      </div>
      <node-view-content
        ref="nodeViewContent"
        as="code"
        class="gl-relative gl-z-1 !gl-break-words"
        :class="{
          'line_content new code': isCodeSuggestion,
          [themeClass]: isCodeSuggestion,
        }"
        spellcheck="false"
        data-testid="suggestion-field"
      />
    </node-view-wrapper>
  </editor-state-observer>
</template>
