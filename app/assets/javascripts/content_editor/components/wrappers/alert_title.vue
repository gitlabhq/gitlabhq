<script>
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import EditorStateObserver from '../editor_state_observer.vue';
import { ALERT_TYPES, DEFAULT_ALERT_TITLES } from '../../constants/alert_types';

const alertTypes = Object.values(ALERT_TYPES);

export default {
  name: 'AlertTitleWrapper',
  components: {
    NodeViewWrapper,
    NodeViewContent,
    EditorStateObserver,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      alertType: ALERT_TYPES.NOTE,
    };
  },
  computed: {
    isEmpty() {
      return this.node.childCount === 0;
    },
    defaultTitle() {
      return DEFAULT_ALERT_TITLES[this.alertType || ALERT_TYPES.NOTE];
    },
  },
  methods: {
    updateNodeView() {
      this.alertType = alertTypes.find((type) =>
        this.$el.closest('.markdown-alert')?.classList.contains(`markdown-alert-${type}`),
      );
    },
  },
};
</script>
<template>
  <node-view-wrapper>
    <p
      v-if="isEmpty"
      class="markdown-alert-title gl-absolute gl-opacity-5"
      :contenteditable="false"
      dir="auto"
    >
      {{ defaultTitle }}
    </p>
    <editor-state-observer :debounce="0" @transaction="updateNodeView" />
    <node-view-content as="p" class="markdown-alert-title" dir="auto" />
  </node-view-wrapper>
</template>
