<script>
import { NodeViewWrapper } from '@tiptap/vue-2';
import { GlLink } from '@gitlab/ui';

export default {
  name: 'ReferenceWrapper',
  components: {
    NodeViewWrapper,
    GlLink,
  },
  inject: ['contentEditor'],
  props: {
    node: {
      type: Object,
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
      href: '#',
    };
  },
  computed: {
    text() {
      return this.node.attrs.text;
    },
    isCommand() {
      return this.node.attrs.referenceType === 'command';
    },
    isMember() {
      return this.node.attrs.referenceType === 'user';
    },
    isCurrentUser() {
      return gon.current_username === this.text.substring(1);
    },
  },
  async mounted() {
    const text = this.node.attrs.originalText || this.node.attrs.text;
    const { href } = await this.contentEditor.resolveReference(text);
    this.href = href || '';
  },
};
</script>
<template>
  <node-view-wrapper as="span">
    <span v-if="isCommand">{{ text }}</span>
    <gl-link
      v-else
      :href="href"
      tabindex="-1"
      class="gfm gl-cursor-text"
      :class="{
        'gfm-project_member': isMember,
        'current-user': isMember && isCurrentUser,
        'ProseMirror-selectednode': selected,
      }"
      @click.prevent.stop
      >{{ text }}</gl-link
    >
  </node-view-wrapper>
</template>
