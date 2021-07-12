<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { INFINITELY_NESTED_COLLAPSIBLE_SECTIONS_FF } from '../../constants';
import LogLine from './line.vue';
import LogLineHeader from './line_header.vue';

export default {
  name: 'CollapsibleLogSection',
  components: {
    LogLine,
    LogLineHeader,
    CollapsibleLogSection: () => import('./collapsible_section.vue'),
  },
  mixins: [glFeatureFlagsMixin()],
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
    infinitelyCollapsibleSectionsFlag() {
      return this.glFeatures?.[INFINITELY_NESTED_COLLAPSIBLE_SECTIONS_FF];
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
      <template v-if="infinitelyCollapsibleSectionsFlag">
        <template v-for="line in section.lines">
          <collapsible-log-section
            v-if="line.isHeader"
            :key="line.line.offset"
            :section="line"
            :trace-endpoint="traceEndpoint"
            @onClickCollapsibleLine="handleOnClickCollapsibleLine"
          />
          <log-line v-else :key="line.offset" :line="line" :path="traceEndpoint" />
        </template>
      </template>
      <template v-else>
        <log-line
          v-for="line in section.lines"
          :key="line.offset"
          :line="line"
          :path="traceEndpoint"
        />
      </template>
    </template>
  </div>
</template>
