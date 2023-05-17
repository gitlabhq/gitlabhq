<script>
import { debounce } from 'lodash';
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import SandboxedMermaid from '~/behaviors/components/sandboxed_mermaid.vue';
import codeBlockLanguageLoader from '../../services/code_block_language_loader';
import EditorStateObserver from '../editor_state_observer.vue';

export default {
  name: 'CodeBlock',
  components: {
    NodeViewWrapper,
    NodeViewContent,
    EditorStateObserver,
    SandboxedMermaid,
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
    };
  },
  async mounted() {
    this.updateDiagramPreview = debounce(
      this.updateDiagramPreview,
      DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
    );

    const lang = codeBlockLanguageLoader.findOrCreateLanguageBySyntax(this.node.attrs.language);
    await codeBlockLanguageLoader.loadLanguage(lang.syntax);

    this.updateAttributes({ language: this.node.attrs.language });
  },
  methods: {
    async updateDiagramPreview() {
      if (!this.node.attrs.showPreview) {
        this.diagramSource = '';
        return;
      }

      if (!this.editor.isActive('diagram')) return;

      this.diagramSource = this.$refs.nodeViewContent.$el.textContent;

      if (this.node.attrs.language !== 'mermaid') {
        this.diagramUrl = await this.contentEditor.renderDiagram(
          this.diagramSource,
          this.node.attrs.language,
        );
      }
    },
  },
  i18n: {
    frontmatter: __('frontmatter'),
  },
  userColorScheme: gon.user_color_scheme,
};
</script>
<template>
  <editor-state-observer @transaction="updateDiagramPreview">
    <node-view-wrapper
      :class="`content-editor-code-block gl-relative code highlight gl-p-3 ${$options.userColorScheme}`"
      as="pre"
      dir="auto"
    >
      <div
        v-if="node.attrs.showPreview"
        class="gl-mt-n3! gl-ml-n4! gl-mr-n4! gl-mb-3 gl-bg-white! gl-p-4 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
      >
        <sandboxed-mermaid v-if="node.attrs.language === 'mermaid'" :source="diagramSource" />
        <img v-else ref="diagramContainer" :src="diagramUrl" />
      </div>
      <span
        v-if="node.attrs.isFrontmatter"
        data-testid="frontmatter-label"
        class="gl-absolute gl-top-0 gl-right-3"
        contenteditable="false"
        >{{ $options.i18n.frontmatter }}:{{ node.attrs.language }}</span
      >
      <node-view-content ref="nodeViewContent" as="code" />
    </node-view-wrapper>
  </editor-state-observer>
</template>
