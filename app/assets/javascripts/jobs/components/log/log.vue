<script>
import { mapState, mapActions } from 'vuex';
import CollpasibleLogSection from './collapsible_section.vue';
import LogLine from './line.vue';

export default {
  components: {
    CollpasibleLogSection,
    LogLine,
  },
  computed: {
    ...mapState(['traceEndpoint', 'trace', 'isTraceComplete']),
  },
  methods: {
    ...mapActions(['toggleCollapsibleLine']),
    handleOnClickCollapsibleLine(section) {
      this.toggleCollapsibleLine(section);
    },
  },
};
</script>
<template>
  <code class="job-log d-block">
    <template v-for="(section, index) in trace">
      <collpasible-log-section
        v-if="section.isHeader"
        :key="`collapsible-${index}`"
        :section="section"
        :trace-endpoint="traceEndpoint"
        @onClickCollapsibleLine="handleOnClickCollapsibleLine"
      />
      <log-line v-else :key="section.offset" :line="section" :path="traceEndpoint" />
    </template>

    <div v-if="!isTraceComplete" class="js-log-animation loader-animation pt-3 pl-3">
      <div class="dot"></div>
      <div class="dot"></div>
      <div class="dot"></div>
    </div>
  </code>
</template>
