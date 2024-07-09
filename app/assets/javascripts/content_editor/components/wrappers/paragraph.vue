<script>
import { debounce } from 'lodash';
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import EditorStateObserver from '../editor_state_observer.vue';

const quickActionRegex = /^\/\w+/;

export default {
  name: 'ParagraphWrapper',
  components: {
    NodeViewWrapper,
    NodeViewContent,
    EditorStateObserver,
  },
  inject: ['contentEditor'],
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      hasQuickAction: false,
      quickActionExplanation: '',
      insertTrailingBreak: false,
    };
  },
  mounted() {
    this.updateQuickActionExplanation = debounce(
      this.updateQuickActionExplanation,
      DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
    );
  },
  methods: {
    async updateNodeView() {
      const isRootElement =
        this.$refs.nodeViewWrapper.$el.parentElement.classList.contains('ProseMirror');

      const content = this.contentEditor.serializer.serialize({ doc: this.node.content }) || '';

      this.hasQuickAction = isRootElement && quickActionRegex.test(content);
      if (!this.hasQuickAction) return;

      await this.updateQuickActionExplanation(content);
    },

    async updateQuickActionExplanation(content) {
      this.quickActionExplanation = await this.contentEditor.explainQuickAction(content);
    },
  },
};
</script>
<template>
  <editor-state-observer @transaction="updateNodeView">
    <node-view-wrapper
      ref="nodeViewWrapper"
      as="p"
      :class="{ 'gl-flex gl-align-items-baseline': quickActionExplanation }"
    >
      <node-view-content
        ref="nodeViewContent"
        as="span"
        :class="{ '!gl-whitespace-nowrap': quickActionExplanation }"
      />
      <span
        v-if="quickActionExplanation"
        class="gl-text-sm gl-text-secondary gl-italic gl-flex-shrink-0"
        contenteditable="false"
      >
        &nbsp;&middot; {{ quickActionExplanation }}</span
      >
    </node-view-wrapper>
  </editor-state-observer>
</template>
