<script>
import CodeCell from '../code/index.vue';
import Html from './html.vue';
import Image from './image.vue';

export default {
  props: {
    codeCssClass: {
      type: String,
      required: false,
      default: '',
    },
    count: {
      type: Number,
      required: false,
      default: 0,
    },
    output: {
      type: Object,
      requred: true,
    },
  },
  components: {
    'code-cell': CodeCell,
    'html-output': Html,
    'image-output': Image,
  },
  data() {
    return {
      outputType: '',
    };
  },
  computed: {
    componentName() {
      if (this.output.text) {
        return 'code-cell';
      } else if (this.output.data['image/png']) {
        this.outputType = 'image/png';

        return 'image-output';
      } else if (this.output.data['text/html']) {
        this.outputType = 'text/html';

        return 'html-output';
      } else if (this.output.data['image/svg+xml']) {
        this.outputType = 'image/svg+xml';

        return 'html-output';
      }

      this.outputType = 'text/plain';
      return 'code-cell';
    },
    rawCode() {
      if (this.output.text) {
        return this.output.text.join('');
      }

      return this.dataForType(this.outputType);
    },
  },
  methods: {
    dataForType(type) {
      let data = this.output.data[type];

      if (typeof data === 'object') {
        data = data.join('');
      }

      return data;
    },
  },
};
</script>

<template>
  <component :is="componentName"
    type="output"
    :outputType="outputType"
    :count="count"
    :raw-code="rawCode"
    :code-css-class="codeCssClass" />
</template>
