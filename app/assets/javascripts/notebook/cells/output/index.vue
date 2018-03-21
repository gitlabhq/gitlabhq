<script>
import CodeCell from '../code/index.vue';
import HtmlOutput from './html.vue';
import ImageOutput from './image.vue';

export default {
  components: {
    CodeCell,
    HtmlOutput,
    ImageOutput,
  },
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
    componentName(output) {
      if (output.text) {
        return 'code-cell';
      } else if (output.data['image/png']) {
        this.outputType = 'image/png';

        return 'image-output';
      } else if (output.data['text/html']) {
        this.outputType = 'text/html';

        return 'html-output';
      } else if (output.data['image/svg+xml']) {
        this.outputType = 'image/svg+xml';

        return 'html-output';
      }

      this.outputType = 'text/plain';
      return 'code-cell';
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
      v-for="(output, index) in outputs"
      :is="componentName(output)"
      type="output"
      :output-type="outputType"
      :count="count"
      :index="index"
      :raw-code="rawCode(output)"
      :code-css-class="codeCssClass"
      :key="index"
    />
  </div>
</template>
