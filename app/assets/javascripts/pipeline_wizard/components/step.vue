<script>
import { GlAlert } from '@gitlab/ui';
import { isNode, isDocument, parseDocument, Document } from 'yaml';
import { merge } from '~/lib/utils/yaml';
import { s__ } from '~/locale';
import { logError } from '~/lib/logger';
import InputWrapper from './input_wrapper.vue';
import StepNav from './step_nav.vue';

export default {
  name: 'PipelineWizardStep',
  i18n: {
    errors: {
      cloneErrorUserMessage: s__(
        'PipelineWizard|There was an unexpected error trying to set up the template. The error has been logged.',
      ),
    },
  },
  components: {
    StepNav,
    InputWrapper,
    GlAlert,
  },
  props: {
    // As the inputs prop we expect to receive an array of instructions
    // on how to display the input fields that will be used to obtain the
    // user's input. Each input instruction needs a target prop, specifying
    // the placeholder in the template that will be replaced by the user's
    // input. The selected widget may require additional validation for the
    // input object.
    inputs: {
      type: Array,
      required: true,
      validator: (value) => value.every((i) => i?.widget),
    },
    template: {
      type: null,
      required: true,
      validator: (v) => isNode(v),
    },
    hasPreviousStep: {
      type: Boolean,
      required: false,
      default: false,
    },
    compiled: {
      type: Object,
      required: true,
      validator: (v) => isDocument(v),
    },
  },
  data() {
    return {
      wasCompiled: false,
      validate: false,
      inputValidStates: Array(this.inputs.length).fill(null),
      error: null,
    };
  },
  computed: {
    inputValidStatesThatAreNotNull() {
      return this.inputValidStates?.filter((s) => s !== null);
    },
    areAllInputValidStatesNull() {
      return !this.inputValidStatesThatAreNotNull?.length;
    },
    isValid() {
      return this.areAllInputValidStatesNull || this.inputValidStatesThatAreNotNull.every((s) => s);
    },
  },
  methods: {
    forceClone(yamlNode) {
      try {
        // document.clone() will only clone the root document object,
        // but the references to the child nodes inside will be retained.
        // So in order to ensure a full clone, we need to stringify
        // and parse until there's a better implementation in the
        // yaml package.
        return parseDocument(new Document(yamlNode).toString());
      } catch (e) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        logError('An unexpected error occurred while trying to clone a template', e);
        this.error = this.$options.i18n.errors.cloneErrorUserMessage;
        return null;
      }
    },
    compile() {
      if (this.wasCompiled) return;
      // NOTE: This modifies this.compiled without triggering reactivity.
      // this is done on purpose, see
      // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/81412#note_862972703
      // for more information
      merge(this.compiled, this.forceClone(this.template));
      this.wasCompiled = true;
    },
    onUpdate(c) {
      this.$emit('update:compiled', c);
    },
    onPrevClick() {
      this.$emit('back');
    },
    async onNextClick() {
      this.validate = true;
      await this.$nextTick();
      if (this.isValid) {
        this.$emit('next');
      }
    },
    onInputValidationStateChange(inputId, value) {
      const copy = [...this.inputValidStates];
      copy[inputId] = value;
      this.inputValidStates = copy;
    },
    onHighlight(path) {
      this.$emit('update:highlight', path);
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="error" class="gl-mb-4" variant="danger">
      {{ error }}
    </gl-alert>
    <input-wrapper
      v-for="(input, i) in inputs"
      :key="input.target"
      :compiled="compiled"
      :target="input.target"
      :template="template"
      :validate="validate"
      :widget="input.widget"
      class="gl-mb-8"
      :monospace="input.monospace"
      v-bind="input"
      @highlight="onHighlight"
      @update:valid="(validationState) => onInputValidationStateChange(i, validationState)"
      @update:compiled="onUpdate"
      @beforeUpdate:compiled.once="compile"
    />
    <step-nav
      :next-button-enabled="isValid"
      :show-back-button="hasPreviousStep"
      show-next-button
      @back="onPrevClick"
      @next="onNextClick"
    />
  </div>
</template>
