<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import DagGraph from './dag_graph.vue';
import DagAnnotations from './dag_annotations.vue';
import {
  DEFAULT,
  PARSE_FAILURE,
  LOAD_FAILURE,
  UNSUPPORTED_DATA,
  ADD_NOTE,
  REMOVE_NOTE,
  REPLACE_NOTES,
} from './constants';
import { parseData } from './parsing_utils';

export default {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'Dag',
  components: {
    DagAnnotations,
    DagGraph,
    GlAlert,
    GlLink,
    GlSprintf,
  },
  props: {
    graphUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      annotationsMap: {},
      failureType: null,
      graphData: null,
      showFailureAlert: false,
      showBetaInfo: true,
    };
  },
  errorTexts: {
    [LOAD_FAILURE]: __('We are currently unable to fetch data for this graph.'),
    [PARSE_FAILURE]: __('There was an error parsing the data for this graph.'),
    [UNSUPPORTED_DATA]: __('DAG visualization requires at least 3 dependent jobs.'),
    [DEFAULT]: __('An unknown error occurred while loading this graph.'),
  },
  computed: {
    betaMessage() {
      return __(
        'This feature is currently in beta. We invite you to %{linkStart}give feedback%{linkEnd}.',
      );
    },
    failure() {
      switch (this.failureType) {
        case LOAD_FAILURE:
          return {
            text: this.$options.errorTexts[LOAD_FAILURE],
            variant: 'danger',
          };
        case PARSE_FAILURE:
          return {
            text: this.$options.errorTexts[PARSE_FAILURE],
            variant: 'danger',
          };
        case UNSUPPORTED_DATA:
          return {
            text: this.$options.errorTexts[UNSUPPORTED_DATA],
            variant: 'info',
          };
        default:
          return {
            text: this.$options.errorTexts[DEFAULT],
            vatiant: 'danger',
          };
      }
    },
    shouldDisplayAnnotations() {
      return !isEmpty(this.annotationsMap);
    },
    shouldDisplayGraph() {
      return Boolean(!this.showFailureAlert && this.graphData);
    },
  },
  mounted() {
    const { processGraphData, reportFailure } = this;

    if (!this.graphUrl) {
      reportFailure();
      return;
    }

    axios
      .get(this.graphUrl)
      .then(response => {
        processGraphData(response.data);
      })
      .catch(() => reportFailure(LOAD_FAILURE));
  },
  methods: {
    addAnnotationToMap({ uid, source, target }) {
      this.$set(this.annotationsMap, uid, { source, target });
    },
    processGraphData(data) {
      let parsed;

      try {
        parsed = parseData(data.stages);
      } catch {
        this.reportFailure(PARSE_FAILURE);
        return;
      }

      if (parsed.links.length < 2) {
        this.reportFailure(UNSUPPORTED_DATA);
        return;
      }

      this.graphData = parsed;
    },
    hideAlert() {
      this.showFailureAlert = false;
    },
    hideBetaInfo() {
      this.showBetaInfo = false;
    },
    removeAnnotationFromMap({ uid }) {
      this.$delete(this.annotationsMap, uid);
    },
    reportFailure(type) {
      this.showFailureAlert = true;
      this.failureType = type;
    },
    updateAnnotation({ type, data }) {
      switch (type) {
        case ADD_NOTE:
          this.addAnnotationToMap(data);
          break;
        case REMOVE_NOTE:
          this.removeAnnotationFromMap(data);
          break;
        case REPLACE_NOTES:
          this.annotationsMap = data;
          break;
        default:
          break;
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="showFailureAlert" :variant="failure.variant" @dismiss="hideAlert">
      {{ failure.text }}
    </gl-alert>

    <gl-alert v-if="showBetaInfo" @dismiss="hideBetaInfo">
      <gl-sprintf :message="betaMessage">
        <template #link="{ content }">
          <gl-link href="https://gitlab.com/gitlab-org/gitlab/-/issues/220368" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
    <div class="gl-relative">
      <dag-annotations v-if="shouldDisplayAnnotations" :annotations="annotationsMap" />
      <dag-graph
        v-if="shouldDisplayGraph"
        :graph-data="graphData"
        @on-failure="reportFailure"
        @update-annotation="updateAnnotation"
      />
    </div>
  </div>
</template>
