<script>
import LogLine from './line.vue';
import LogLineHeader from './line_header.vue';

export default {
  name: 'CollapsibleLogSection',
  components: {
    LogLine,
    LogLineHeader,
  },
  props: {
    section: {
      type: Object,
      required: true,
    },
    jobLogEndpoint: {
      type: String,
      required: true,
    },
    searchResults: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    badgeDuration() {
      return this.section.line && this.section.line.section_duration;
    },
    highlightedLines() {
      return this.searchResults.map((result) => result.lineNumber);
    },
    headerIsHighlighted() {
      const {
        line: { lineNumber },
      } = this.section;

      return this.highlightedLines.includes(lineNumber);
    },
  },
  methods: {
    handleOnClickCollapsibleLine(section) {
      this.$emit('onClickCollapsibleLine', section);
    },
    lineIsHighlighted({ lineNumber }) {
      return this.highlightedLines.includes(lineNumber);
    },
  },
};
</script>
<template>
  <div>
    <log-line-header
      :line="section.line"
      :duration="badgeDuration"
      :path="jobLogEndpoint"
      :is-closed="section.isClosed"
      :is-highlighted="headerIsHighlighted"
      @toggleLine="handleOnClickCollapsibleLine(section)"
    />
    <template v-if="!section.isClosed">
      <log-line
        v-for="line in section.lines"
        :key="line.offset"
        :line="line"
        :path="jobLogEndpoint"
        :is-highlighted="lineIsHighlighted(line)"
      />
    </template>
  </div>
</template>
