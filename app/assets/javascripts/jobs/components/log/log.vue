<script>
import { mapState, mapActions } from 'vuex';
import LogLine from './line.vue';
import LogLineHeader from './line_header.vue';

export default {
  components: {
    LogLine,
    LogLineHeader,
  },
  computed: {
    ...mapState(['traceEndpoint', 'trace']),
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
  <code class="job-log">
    <template v-for="(section, index) in trace">
      <template v-if="section.isHeader">
        <log-line-header
          :key="`collapsible-${index}`"
          :line="section.line"
          :path="traceEndpoint"
          :is-closed="section.isClosed"
          @toggleLine="handleOnClickCollapsibleLine(section)"
        />
        <template v-if="!section.isClosed">
          <log-line
            v-for="line in section.lines"
            :key="line.offset"
            :line="line"
            :path="traceEndpoint"
          />
        </template>
      </template>
      <log-line v-else :key="section.offset" :line="section" :path="traceEndpoint" />
    </template>
  </code>
</template>
