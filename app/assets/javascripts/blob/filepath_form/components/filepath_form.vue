<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import TemplateSelector from '~/blob/filepath_form/components/template_selector.vue';

export default {
  components: {
    GlFormGroup,
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
  <div class="gl-mr-3 gl-flex gl-w-full gl-flex-col gl-gap-3 lg:gl-w-auto lg:gl-flex-row">
    <gl-form-group
      class="gl-mb-0"
      :label="inputOptions.label"
      :label-for="inputOptions.id"
      label-class="gl-sr-only"
    >
      <gl-form-input v-model="filename" v-bind="inputOptions" />
    </gl-form-group>
    <template-selector
      v-if="showTemplateSelector"
      :filename="filename"
      :templates="templates"
      :initial-template="initialTemplate"
      @selected="onTemplateSelected"
    />
  </div>
</template>
