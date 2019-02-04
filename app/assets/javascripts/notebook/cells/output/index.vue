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
  },
  data() {
    return {
      outputType: '',
    };
  },
  methods: {
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
        this.outputType = 'image/png';

        return ImageOutput;
      } else if (output.data['text/html']) {
        this.outputType = 'text/html';

        return HtmlOutput;
      } else if (output.data['image/svg+xml']) {
        this.outputType = 'image/svg+xml';

        return HtmlOutput;
      }

      this.outputType = 'text/plain';
      return CodeOutput;
    },
    rawCode(output) {
      if (output.text) {
        return output.text.join('');
      }

      return this.dataForType(output, this.outputType);
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
      :output-type="outputType"
      :count="count"
      :index="index"
      :raw-code="rawCode(output)"
      :code-css-class="codeCssClass"
    />
  </div>
</template>
