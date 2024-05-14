<script>
import { memoize } from 'lodash';
import { reportToSentry } from '~/ci/utils';
import { parseData } from '~/ci/pipeline_details/utils/parsing_utils';
import LinksInner from '~/ci/pipeline_details/graph/components/links_inner.vue';

const parseForLinksBare = (pipeline) => {
  const arrayOfJobs = pipeline.flatMap(({ groups }) => groups);
  return parseData(arrayOfJobs).links;
};

const parseForLinks = memoize(parseForLinksBare);

export default {
  name: 'LinksLayer',
  components: {
    LinksInner,
  },
  props: {
    containerMeasurements: {
      type: Object,
      required: true,
    },
    pipelineData: {
      type: Array,
      required: true,
    },
    linksData: {
      type: Array,
      required: false,
      default: () => [],
    },
    showLinks: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    containerZero() {
      return !this.containerMeasurements.width || !this.containerMeasurements.height;
    },
    getLinksData() {
      if (this.linksData.length > 0) {
        return this.linksData;
      }

      return parseForLinks(this.pipelineData);
    },
    showLinkedLayers() {
      return this.showLinks && !this.containerZero;
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry(this.$options.name, `error: ${err}, info: ${info}`);
  },
};
</script>
<template>
  <links-inner
    v-if="showLinkedLayers"
    :container-measurements="containerMeasurements"
    :links-data="getLinksData"
    :pipeline-data="pipelineData"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <slot></slot>
  </links-inner>
  <div v-else>
    <div class="gl-display-flex gl-flex-wrap gl-sm-flex-nowrap gl-relative">
      <slot></slot>
    </div>
  </div>
</template>
