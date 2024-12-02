<script>
import { debounce } from 'lodash';
import { NodeViewWrapper } from '@tiptap/vue-2';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { getHeadings } from '../../services/table_of_contents_utils';
import TableOfContentsHeading from './table_of_contents_heading.vue';

export default {
  name: 'TableOfContentsWrapper',
  components: {
    NodeViewWrapper,
    TableOfContentsHeading,
  },
  props: {
    editor: {
      type: Object,
      required: true,
    },
    node: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      headings: [],
    };
  },
  mounted() {
    this.handleUpdate = debounce(this.handleUpdate, DEFAULT_DEBOUNCE_AND_THROTTLE_MS * 2);

    this.editor.on('update', this.handleUpdate);
    this.$nextTick(this.handleUpdate);
  },
  methods: {
    handleUpdate() {
      this.headings = getHeadings(this.editor);
    },
  },
};
</script>
<template>
  <node-view-wrapper
    as="ul"
    class="table-of-contents gl-mb-5 gl-border-1 gl-border-solid gl-border-default !gl-p-4"
    data-testid="table-of-contents"
  >
    {{ __('Table of contents') }}
    <table-of-contents-heading
      v-for="(heading, index) in headings"
      :key="index"
      :heading="heading"
    />
  </node-view-wrapper>
</template>
