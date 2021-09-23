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
    jobLogEndpoint: {
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
      :path="jobLogEndpoint"
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
            :job-log-endpoint="jobLogEndpoint"
            @onClickCollapsibleLine="handleOnClickCollapsibleLine"
          />
          <log-line v-else :key="line.offset" :line="line" :path="jobLogEndpoint" />
        </template>
      </template>
      <template v-else>
        <log-line
          v-for="line in section.lines"
          :key="line.offset"
          :line="line"
          :path="jobLogEndpoint"
        />
      </template>
    </template>
  </div>
</template>
