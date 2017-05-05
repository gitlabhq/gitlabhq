<script>
import eventHub from '../event_hub';
import IssueToken from './issue_token.vue';

export default {
  name: 'AddIssuableForm',

  props: {
    inputValue: {
      type: String,
      required: true,
    },
    addButtonLabel: {
      type: String,
      required: true,
    },
    pendingIssuables: {
      type: Array,
      required: false,
      default: () => [],
    },
  },

  data() {
    return {
      isInputFocused: false,
    };
  },

  components: {
    issueToken: IssueToken,
  },

  methods: {
    onInput() {
      const value = this.$refs.input.value;
      eventHub.$emit('addIssuableFormInput', value, $(this.$refs.input).caret('pos'));
    },
    onFocus() {
      this.isInputFocused = true;
    },
    onBlur() {
      this.isInputFocused = false;

      const value = this.$refs.input.value;
      eventHub.$emit('addIssuableFormBlur', value);
    },
    onInputWrapperClick() {
      this.$refs.input.focus();
    },
    onFormSubmit() {
      eventHub.$emit('addIssuableFormSubmit');
    },
    onFormCancel() {
      eventHub.$emit('addIssuableFormCancel');
    },
  },

  mounted() {
    const $input = $(this.$refs.input);
    gl.GfmAutoComplete.setup($input, {
      issues: true,
    });
    $input.on('inserted-issues.atwho', this.onInput);
  },

  beforeDestroy() {
    const $input = $(this.$refs.input);
    $input.off('inserted-issues.atwho', this.onInput);
  },
};
</script>

<template>
  <div>
    <div
      ref="issuableFormWrapper"
      class="add-issuable-form-input-wrapper form-control"
      :class="{ focus: isInputFocused }"
      role="button"
      @click="onInputWrapperClick">
      <ul class="add-issuable-form-input-token-list">
        <li
          :key="issuable.reference"
          v-for="issuable in pendingIssuables"
          class="js-add-issuable-form-token-list-item add-issuable-form-token-list-item">
          <issue-token
            event-namespace="pendingIssuable"
            :reference="issuable.reference"
            :display-reference="issuable.displayReference"
            :title="issuable.title"
            :path="issuable.path"
            :state="issuable.state"
            :fetch-status="issuable.fetchStatus"
            :can-remove="true" />
        </li>
        <li class="add-issuable-form-input-list-item">
          <input
            ref="input"
            type="text"
            class="add-issuable-form-input"
            :value="inputValue"
            placeholder="Search issues..."
            @input="onInput"
            @focus="onFocus"
            @blur="onBlur" />
        </li>
      </ul>
    </div>
    <div class="clearfix prepend-top-10">
      <button
        ref="addButton"
        type="button"
        class="btn btn-new pull-left"
        @click="onFormSubmit">
        {{ addButtonLabel }}
      </button>
      <button
        type="button"
        class="btn btn-default pull-right"
        @click="onFormCancel">
        Cancel
      </button>
    </div>
  </div>
</template>
