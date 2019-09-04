<script>
import Icon from '~/vue_shared/components/icon.vue';
import LineNumber from './line_number.vue';

export default {
  components: {
    Icon,
    LineNumber,
  },
  props: {
    line: {
      type: Object,
      required: true,
    },
    isClosed: {
      type: Boolean,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
  },
  computed: {
    iconName() {
      return this.isClosed ? 'angle-right' : 'angle-down';
    },
  },
  methods: {
    handleOnClick() {
      this.$emit('toggleLine');
    },
  },
};
</script>

<template>
  <div class="line collapsible-line" role="button" @click="handleOnClick">
    <icon :name="iconName" class="arrow" />
    <line-number :line-number="line.lineNumber" :path="path" />
    <span v-for="(content, i) in line.content" :key="i" class="line-text" :class="content.style">{{
      content.text
    }}</span>
  </div>
</template>
