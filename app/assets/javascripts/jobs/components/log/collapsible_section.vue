<script>
import LogLine from './line.vue';
import LogLineHeader from './line_header.vue';

export default {
  name: 'CollpasibleLogSection',
  components: {
    LogLine,
    LogLineHeader,
  },
  props: {
    section: {
      type: Object,
      required: true,
    },
    traceEndpoint: {
      type: String,
      required: true,
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
      :path="traceEndpoint"
      :is-closed="section.isClosed"
      @toggleLine="handleOnClickCollapsibleLine(section)"
    />
    <template v-if="!section.isClosed">
      <template v-for="line in section.lines">
        <collpasible-log-section
          v-if="line.isHeader"
          :key="`collapsible-nested-${line.offset}`"
          :section="line"
          :trace-endpoint="traceEndpoint"
          @toggleLine="handleOnClickCollapsibleLine"
        />
        <log-line v-else :key="line.offset" :line="line" :path="traceEndpoint" />
      </template>
    </template>
  </div>
</template>
