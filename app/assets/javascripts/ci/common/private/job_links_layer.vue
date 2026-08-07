<script>
import { memoize } from 'lodash-es';
import { parseData } from '~/ci/pipeline_details/utils/parsing_utils';
import LinksInner from '~/ci/pipeline_details/graph/components/links_inner.vue';
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

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
  mixins: [glListenersMixin],
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
};
</script>
<template>
  <links-inner
    v-if="showLinkedLayers"
    :container-measurements="containerMeasurements"
    :links-data="getLinksData"
    :pipeline-data="pipelineData"
    v-bind="$attrs"
    v-on="glListeners()"
  >
    <slot></slot>
  </links-inner>
  <div v-else>
    <div class="gl-relative gl-flex gl-flex-wrap @sm/panel:gl-flex-nowrap">
      <slot></slot>
    </div>
  </div>
</template>
