<script>
import { COMMON_HANDLES, PATH_HANDLE, SEARCH_SCOPE_PLACEHOLDER } from './constants';

export default {
  name: 'FakeSearchInput',
  props: {
    userInput: {
      type: String,
      required: true,
    },
    scope: {
      type: String,
      required: true,
      validator: (value) => [...COMMON_HANDLES, PATH_HANDLE].includes(value),
    },
  },
  computed: {
    placeholder() {
      return SEARCH_SCOPE_PLACEHOLDER[this.scope];
    },
  },
};
</script>

<template>
  <div class="fake-input gl-pointer-events-none gl-flex">
    <span class="gl-opacity-0" data-testid="search-scope">{{ scope }}&nbsp;</span>
    <span
      v-if="!userInput"
      data-testid="search-scope-placeholder"
      class="gl-pointer-events-none gl-text-subtle"
      >{{ placeholder }}</span
    >
  </div>
</template>

<style scoped>
.fake-input {
  position: absolute;
  top: 14px;
  left: 39px;
}
</style>
