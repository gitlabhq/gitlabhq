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
      :file-path="entry.filename"
      :error-line="entry.lineNo"
      :error-fn="entry.function"
      :error-column="entry.colNo"
      :expanded="isFirstEntry(index)"
    />
  </div>
</template>
