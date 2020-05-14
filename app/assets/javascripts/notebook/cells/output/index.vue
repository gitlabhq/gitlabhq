<script>
import CodeOutput from '../code/index.vue';
import HtmlOutput from './html.vue';
import ImageOutput from './image.vue';

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
    outputs: {
      type: Array,
      required: true,
    },
    metadata: {
      type: Object,
      default: () => ({}),
      required: false,
    },
  },
  methods: {
    outputType(output) {
      if (output.text) {
        return 'text/plain';
      } else if (output.data['image/png']) {
        return 'image/png';
      } else if (output.data['text/html']) {
        return 'text/html';
      } else if (output.data['image/svg+xml']) {
        return 'image/svg+xml';
      }

      return 'text/plain';
    },
    dataForType(output, type) {
      let data = output.data[type];

      if (typeof data === 'object') {
        data = data.join('');
      }

      return data;
    },
    getComponent(output) {
      if (output.text) {
        return CodeOutput;
      } else if (output.data['image/png']) {
        return ImageOutput;
      } else if (output.data['text/html']) {
        return HtmlOutput;
      } else if (output.data['image/svg+xml']) {
        return HtmlOutput;
      }

      return CodeOutput;
    },
    rawCode(output) {
      if (output.text) {
        if (typeof output.text === 'string') {
          return output.text;
        }
        return output.text.join('');
      }

      return this.dataForType(output, this.outputType(output));
    },
  },
};
</script>

<template>
  <div>
    <component
      :is="getComponent(output)"
      v-for="(output, index) in outputs"
      :key="index"
      type="output"
      :output-type="outputType(output)"
      :count="count"
      :index="index"
      :raw-code="rawCode(output)"
      :metadata="metadata"
      :code-css-class="codeCssClass"
    />
  </div>
</template>
