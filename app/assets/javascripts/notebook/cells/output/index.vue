<!-- eslint-disable vue/multi-word-component-names -->
<script>
import CodeOutput from '../code/index.vue';
import HtmlOutput from './html.vue';
import ImageOutput from './image.vue';
import LatexOutput from './latex.vue';
import MarkdownOutput from './markdown.vue';
import ErrorOutput from './error.vue';
import DataframeOutput from './dataframe.vue';
import { isDataframe } from './dataframe_util';

const TEXT_MARKDOWN = 'text/markdown';
const ERROR_OUTPUT_TYPE = 'error';

export default {
  props: {
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
      }
      if (output.output_type === ERROR_OUTPUT_TYPE) {
        return 'error';
      }
      if (output.data['image/png']) {
        return 'image/png';
      }
      if (output.data['image/jpeg']) {
        return 'image/jpeg';
      }
      if (output.data['text/html']) {
        return 'text/html';
      }
      if (output.data['text/latex']) {
        return 'text/latex';
      }
      if (output.data['image/svg+xml']) {
        return 'image/svg+xml';
      }
      if (output.data[TEXT_MARKDOWN]) {
        return TEXT_MARKDOWN;
      }

      return 'text/plain';
    },
    dataForType(output, type) {
      let data = output.data[type];

      if (typeof data === 'object' && this.outputType(output) !== TEXT_MARKDOWN) {
        data = data.join('');
      }

      return data;
    },
    getComponent(output) {
      if (output.text) {
        return CodeOutput;
      }
      if (output.output_type === ERROR_OUTPUT_TYPE) {
        return ErrorOutput;
      }
      if (output.data['image/png']) {
        return ImageOutput;
      }
      if (output.data['image/jpeg']) {
        return ImageOutput;
      }
      if (isDataframe(output)) {
        return DataframeOutput;
      }
      if (output.data['text/html']) {
        return HtmlOutput;
      }
      if (output.data['text/latex']) {
        return LatexOutput;
      }
      if (output.data['image/svg+xml']) {
        return HtmlOutput;
      }
      if (output.data[TEXT_MARKDOWN]) {
        return MarkdownOutput;
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

      if (output.output_type === ERROR_OUTPUT_TYPE) {
        return output.traceback;
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
    />
  </div>
</template>
