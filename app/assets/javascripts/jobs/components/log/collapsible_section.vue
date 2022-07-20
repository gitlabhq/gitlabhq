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
  },
  methods: {
    handleOnClickCollapsibleLine(section) {
      this.$emit('onClickCollapsibleLine', section);
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
      @toggleLine="handleOnClickCollapsibleLine(section)"
    />
    <template v-if="!section.isClosed">
      <log-line
        v-for="line in section.lines"
        :key="line.offset"
        :line="line"
        :path="jobLogEndpoint"
        :search-results="searchResults"
      />
    </template>
  </div>
</template>
