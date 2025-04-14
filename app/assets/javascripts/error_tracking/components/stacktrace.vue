<!-- eslint-disable vue/multi-word-component-names -->
<script>
import StackTraceEntry from './stacktrace_entry.vue';

export default {
  components: {
    StackTraceEntry,
  },
  props: {
    entries: {
      type: Array,
      required: true,
    },
  },
  methods: {
    isFirstEntry(index) {
      return index === 0;
    },
  },
};
</script>

<template>
  <div class="stacktrace">
    <stack-trace-entry
      v-for="(entry, index) in entries"
      :key="`stacktrace-entry-${index}`"
      :lines="entry.context"
      :file-path="entry.filename || entry.abs_path || entry.absolutePath"
      :error-line="entry.lineNo || entry.lineNumber"
      :error-fn="entry.function"
      :error-column="entry.colNo || entry.columnNumber"
      :expanded="isFirstEntry(index)"
    />
  </div>
</template>
