<script>
import { GlFormInput } from '@gitlab/ui';
import TemplateSelector from '~/blob/filepath_form/components/template_selector.vue';

export default {
  components: {
    GlFormInput,
    TemplateSelector,
  },
  props: {
    templates: {
      type: Object,
      required: true,
    },
    initialTemplate: {
      type: String,
      required: false,
      default: undefined,
    },
    inputOptions: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      filename: this.inputOptions.value || '',
      showTemplateSelector: true,
    };
  },
  beforeMount() {
    const navLinksElement = document.querySelector('.file-editor .nav-links');
    navLinksElement?.addEventListener('click', (e) => {
      this.showTemplateSelector = e.target.href.split('#')[1] !== 'preview';
    });
  },
  methods: {
    onTemplateSelected(data) {
      this.$emit('template-selected', data);
    },
  },
};
</script>
<template>
  <div
    class="gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row gl-w-full gl-lg-w-auto gl-gap-3 gl-mr-3"
  >
    <gl-form-input v-model="filename" v-bind="inputOptions" />
    <template-selector
      v-if="showTemplateSelector"
      :filename="filename"
      :templates="templates"
      :initial-template="initialTemplate"
      @selected="onTemplateSelected"
    />
  </div>
</template>
