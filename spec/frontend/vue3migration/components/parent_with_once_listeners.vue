<script>
import ChildEmittingHyphenatedEvent from './child_emitting_hyphenated_event.vue';

export default {
  name: 'ParentWithOnceListeners',
  components: { ChildEmittingHyphenatedEvent },
  data() {
    return { plainCount: 0, hyphenatedCount: 0 };
  },
  methods: {
    onPlain() {
      this.plainCount += 1;
    },
    onTwoWords() {
      this.hyphenatedCount += 1;
    },
  },
};
</script>

<template>
  <div>
    <child-emitting-hyphenated-event data-testid="plain-child" @plain.once="onPlain" />
    <child-emitting-hyphenated-event data-testid="hyphenated-child" @two-words.once="onTwoWords" />
    <span data-testid="plain-count">{{ plainCount }}</span>
    <span data-testid="hyphenated-count">{{ hyphenatedCount }}</span>
  </div>
</template>
