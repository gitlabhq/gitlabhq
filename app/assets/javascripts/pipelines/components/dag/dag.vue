<script>
import { GlAlert, GlButton, GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { fetchPolicies } from '~/lib/graphql';
import { __ } from '~/locale';
import { DEFAULT, PARSE_FAILURE, LOAD_FAILURE, UNSUPPORTED_DATA } from '../../constants';
import getDagVisData from '../../graphql/queries/get_dag_vis_data.query.graphql';
import { parseData } from '../parsing_utils';
import { ADD_NOTE, REMOVE_NOTE, REPLACE_NOTES } from './constants';
import DagAnnotations from './dag_annotations.vue';
import DagGraph from './dag_graph.vue';

export default {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'Dag',
  components: {
    DagAnnotations,
    DagGraph,
    GlAlert,
    GlButton,
    GlEmptyState,
    GlLink,
    GlSprintf,
  },
  inject: {
    aboutDagDocPath: {
      default: null,
    },
    dagDocPath: {
      default: null,
    },
    emptySvgPath: {
      default: '',
    },
    pipelineIid: {
      default: '',
    },
    pipelineProjectPath: {
      default: '',
    },
  },
  apollo: {
    graphData: {
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      query: getDagVisData,
      variables() {
        return {
          projectPath: this.pipelineProjectPath,
          iid: this.pipelineIid,
        };
      },
      update(data) {
        if (!data?.project?.pipeline) {
          return this.graphData;
        }

        const {
          stages: { nodes: stages },
        } = data.project.pipeline;

        const unwrappedGroups = stages
          .map(({ name, groups: { nodes: groups } }) => {
            return groups.map((group) => {
              return { category: name, ...group };
            });
          })
          .flat(2);

        const nodes = unwrappedGroups.map((group) => {
          const jobs = group.jobs.nodes.map(({ name, needs }) => {
            return { name, needs: needs.nodes.map((need) => need.name) };
          });

          return { ...group, jobs };
        });

        return nodes;
      },
      error() {
        this.reportFailure(LOAD_FAILURE);
      },
    },
  },
  data() {
    return {
      annotationsMap: {},
      failureType: null,
      graphData: null,
      showFailureAlert: false,
      hasNoDependentJobs: false,
    };
  },
  errorTexts: {
    [LOAD_FAILURE]: __('We are currently unable to fetch data for this graph.'),
    [PARSE_FAILURE]: __('There was an error parsing the data for this graph.'),
    [UNSUPPORTED_DATA]: __('DAG visualization requires at least 3 dependent jobs.'),
    [DEFAULT]: __('An unknown error occurred while loading this graph.'),
  },
  emptyStateTexts: {
    title: __('Speed up your pipelines with Needs relationships'),
    firstDescription: __(
      'Using the %{codeStart}needs%{codeEnd} keyword makes jobs run before their stage is reached. Jobs run as soon as their %{codeStart}needs%{codeEnd} relationships are met, which speeds up your pipelines.',
    ),
    secondDescription: __(
      "If you add %{codeStart}needs%{codeEnd} to jobs in your pipeline you'll be able to view the %{codeStart}needs%{codeEnd} relationships between jobs in this tab as a %{linkStart}Directed Acyclic Graph (DAG)%{linkEnd}.",
    ),
    button: __('Learn more about Needs relationships'),
  },
  computed: {
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
            variant: 'danger',
          };
      }
    },
    processedData() {
      return this.processGraphData(this.graphData);
    },
    shouldDisplayAnnotations() {
      return !isEmpty(this.annotationsMap);
    },
    shouldDisplayGraph() {
      return Boolean(!this.showFailureAlert && !this.hasNoDependentJobs && this.graphData);
    },
  },
  methods: {
    addAnnotationToMap({ uid, source, target }) {
      this.$set(this.annotationsMap, uid, { source, target });
    },
    processGraphData(data) {
      let parsed;

      try {
        parsed = parseData(data);
      } catch {
        this.reportFailure(PARSE_FAILURE);
        return {};
      }

      if (parsed.links.length === 1) {
        this.reportFailure(UNSUPPORTED_DATA);
        return {};
      }

      // If there are no links, we don't report failure
      // as it simply means the user does not use job dependencies
      if (parsed.links.length === 0) {
        this.hasNoDependentJobs = true;
        return {};
      }

      return parsed;
    },
    hideAlert() {
      this.showFailureAlert = false;
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

    <div class="gl-relative">
      <dag-annotations v-if="shouldDisplayAnnotations" :annotations="annotationsMap" />
      <dag-graph
        v-if="shouldDisplayGraph"
        :graph-data="processedData"
        @onFailure="reportFailure"
        @update-annotation="updateAnnotation"
      />
      <gl-empty-state
        v-else-if="hasNoDependentJobs"
        :svg-path="emptySvgPath"
        :title="$options.emptyStateTexts.title"
      >
        <template #description>
          <div class="gl-text-left">
            <p>
              <gl-sprintf :message="$options.emptyStateTexts.firstDescription">
                <template #code="{ content }">
                  <code>{{ content }}</code>
                </template>
              </gl-sprintf>
            </p>
            <p>
              <gl-sprintf :message="$options.emptyStateTexts.secondDescription">
                <template #code="{ content }">
                  <code>{{ content }}</code>
                </template>
                <template #link="{ content }">
                  <gl-link :href="aboutDagDocPath">{{ content }}</gl-link>
                </template>
              </gl-sprintf>
            </p>
          </div>
        </template>
        <template v-if="dagDocPath" #actions>
          <gl-button :href="dagDocPath" target="__blank" variant="success">
            {{ $options.emptyStateTexts.button }}
          </gl-button>
        </template>
      </gl-empty-state>
    </div>
  </div>
</template>
