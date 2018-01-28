<script>
  import CodeCell from '../code/index.vue';
  import Html from './html.vue';
  import Image from './image.vue';

  export default {
    components: {
      'code-cell': CodeCell,
      'html-output': Html,
      'image-output': Image,
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
      output: {
        type: Object,
        requred: true,
        default: () => ({}),
      },
    },
    computed: {
      componentName() {
        if (this.output.text) {
          return 'code-cell';
        } else if (this.output.data['image/png']) {
          return 'image-output';
        } else if (this.output.data['text/html']) {
          return 'html-output';
        } else if (this.output.data['image/svg+xml']) {
          return 'html-output';
        }

        return 'code-cell';
      },
      rawCode() {
        if (this.output.text) {
          return this.output.text.join('');
        }

        return this.dataForType(this.outputType);
      },
      outputType() {
        if (this.output.text) {
          return '';
        } else if (this.output.data['image/png']) {
          return 'image/png';
        } else if (this.output.data['text/html']) {
          return 'text/html';
        } else if (this.output.data['image/svg+xml']) {
          return 'image/svg+xml';
        }

        return 'text/plain';
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
  <component
    :is="componentName"
    type="output"
    :output-type="outputType"
    :count="count"
    :raw-code="rawCode"
    :code-css-class="codeCssClass"
  />
</template>
