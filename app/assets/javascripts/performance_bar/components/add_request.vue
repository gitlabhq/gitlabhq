<script>
import { GlForm, GlFormInput, GlButton } from '@gitlab/ui';

export default {
  components: {
    GlForm,
    GlButton,
    GlFormInput,
  },
  data() {
    return {
      inputEnabled: false,
      urlOrRequestId: '',
    };
  },
  methods: {
    toggleInput() {
      this.inputEnabled = !this.inputEnabled;
    },
    addRequest() {
      this.$emit('add-request', this.urlOrRequestId);
      this.clearForm();
    },
    clearForm() {
      this.urlOrRequestId = '';
      this.toggleInput();
    },
  },
};
</script>
<template>
  <div id="peek-view-add-request" class="view gl-display-flex">
    <gl-form class="gl-display-flex gl-align-items-center" @submit.prevent>
      <gl-button
        class="gl-text-blue-300! gl-mr-2"
        category="tertiary"
        variant="link"
        icon="plus"
        size="small"
        :title="__('Add request manually')"
        @click="toggleInput"
      />
      <gl-form-input
        v-if="inputEnabled"
        v-model="urlOrRequestId"
        type="text"
        :placeholder="__(`URL or request ID`)"
        class="gl-ml-2"
        @keyup.enter="addRequest"
        @keyup.esc="clearForm"
      />
    </gl-form>
  </div>
</template>
