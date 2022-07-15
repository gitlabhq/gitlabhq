<script>
import { GlFormGroup, GlButton, GlFormInput } from '@gitlab/ui';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import { resourceLinksFormI18n } from '../constants';

export default {
  name: 'AddIssuableResourceLinkForm',
  components: {
    GlFormGroup,
    GlButton,
    GlFormInput,
  },
  i18n: resourceLinksFormI18n,
  directives: {
    autofocusonshow,
  },
  props: {
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      linkTextValue: '',
      linkValue: '',
    };
  },
  computed: {
    isSubmitButtonDisabled() {
      return this.linkValue.length === 0 || this.isSubmitting;
    },
  },
  methods: {
    onFormCancel() {
      this.linkValue = '';
      this.linkTextValue = '';
      this.$emit('add-issuable-resource-link-form-cancel');
    },
  },
};
</script>

<template>
  <form @submit.prevent>
    <gl-form-group :label="$options.i18n.linkTextLabel">
      <gl-form-input
        v-model="linkTextValue"
        v-autofocusonshow
        data-testid="link-text-input"
        type="text"
      />
    </gl-form-group>
    <gl-form-group :label="$options.i18n.linkValueLabel">
      <gl-form-input v-model="linkValue" data-testid="link-value-input" type="text" />
    </gl-form-group>
    <div class="gl-mt-5 gl-clearfix">
      <gl-button
        category="primary"
        variant="confirm"
        data-testid="add-button"
        :disabled="isSubmitButtonDisabled"
        :loading="isSubmitting"
        type="submit"
        class="gl-float-left"
      >
        {{ $options.i18n.submitButtonText }}
      </gl-button>
      <gl-button class="gl-float-right" @click="onFormCancel">
        {{ $options.i18n.cancelButtonText }}
      </gl-button>
    </div>
  </form>
</template>
