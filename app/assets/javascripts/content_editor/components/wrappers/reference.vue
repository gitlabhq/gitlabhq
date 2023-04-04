<script>
import { NodeViewWrapper } from '@tiptap/vue-2';
import { GlLink } from '@gitlab/ui';

export default {
  name: 'DetailsWrapper',
  components: {
    NodeViewWrapper,
    GlLink,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
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
};
</script>
<template>
  <node-view-wrapper class="gl-display-inline-block">
    <span v-if="isCommand">{{ text }}</span>
    <gl-link
      v-else
      href="#"
      class="gfm"
      :class="{ 'gfm-project_member': isMember, 'current-user': isMember && isCurrentUser }"
      @click.prevent.stop
      >{{ text }}</gl-link
    >
  </node-view-wrapper>
</template>
