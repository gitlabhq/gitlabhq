import { __ } from '~/locale';

<script>
export default {
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
  <div id="peek-view-add-request" class="view">
    <form class="form-inline" @submit.prevent>
      <button
        class="btn-blank btn-link bold"
        type="button"
        :title="__(`Add request manually`)"
        @click="toggleInput"
      >
        +
      </button>
      <input
        v-if="inputEnabled"
        v-model="urlOrRequestId"
        type="text"
        :placeholder="__(`URL or request ID`)"
        class="form-control form-control-sm d-inline-block ml-1"
        @keyup.enter="addRequest"
        @keyup.esc="clearForm"
      />
    </form>
  </div>
</template>
