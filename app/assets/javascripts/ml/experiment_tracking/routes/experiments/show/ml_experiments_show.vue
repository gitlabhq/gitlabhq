<script>
import VueRouter from 'vue-router';
import { GlButton, GlTab, GlTabs, GlBadge, GlSprintf, GlIcon, GlLink } from '@gitlab/ui';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import CandidateList from '~/ml/experiment_tracking/components/candidate_list.vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import ExperimentMetadata from '~/ml/experiment_tracking/components/experiment_metadata.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  ROUTE_DETAILS,
  ROUTE_CANDIDATES,
  ROUTE_PERFORMANCE,
} from '~/ml/experiment_tracking/constants';
import { s__ } from '~/locale';
import PerformanceGraph from '~/ml/experiment_tracking/components/performance_graph.vue';

import * as translations from './translations';

const routes = [
  {
    path: '/',
    name: ROUTE_DETAILS,
    component: ExperimentMetadata,
  },
  {
    path: '/candidates',
    name: ROUTE_CANDIDATES,
    component: CandidateList,
  },
  {
    path: '/performance',
    name: ROUTE_PERFORMANCE,
    component: PerformanceGraph,
  },
  { path: '*', redirect: { name: ROUTE_DETAILS } },
];

export default {
  name: 'MlExperimentsShow',
  components: {
    TimeAgoTooltip,
    TitleArea,
    GlSprintf,
    GlButton,
    DeleteButton,
    GlTabs,
    GlTab,
    GlBadge,
    GlIcon,
    GlLink,
  },
  router: new VueRouter({
    routes,
  }),
  provide() {
    return {
      mlflowTrackingUrl: this.mlflowTrackingUrl,
    };
  },
  props: {
    experiment: {
      type: Object,
      required: true,
    },
    candidates: {
      type: Array,
      required: true,
    },
    metricNames: {
      type: Array,
      required: true,
    },
    paramNames: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    mlflowTrackingUrl: {
      type: String,
      required: false,
      default: '',
    },
    canWriteModelExperiments: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      experimentGid: convertToGraphQLId('Ml::Experiment', this.experiment.id),
    };
  },
  computed: {
    deleteButtonInfo() {
      return {
        deletePath: this.experiment.path,
        deleteConfirmationText: translations.DELETE_EXPERIMENT_CONFIRMATION_MESSAGE,
        actionPrimaryText: translations.DELETE_EXPERIMENT_PRIMARY_ACTION_LABEL,
        modalTitle: translations.DELETE_EXPERIMENT_MODAL_TITLE,
      };
    },
    tabIndex() {
      return routes.findIndex(({ name }) => name === this.$route.name);
    },
    candidatesCount() {
      return this.candidates.length;
    },
    createdMessage() {
      return s__('MlExperimentTracking|Experiment created %{timeAgo} by %{author}');
    },
    showDeleteButton() {
      return !this.experiment.model_id && this.canWriteModelExperiments;
    },
  },
  methods: {
    downloadCsv() {
      const currentPath = window.location.pathname;
      const currentSearch = window.location.search;

      visitUrl(`${currentPath}.csv${currentSearch}`);
    },
    goTo(name) {
      if (name !== this.$route.name) {
        this.$router.push({ name });
      }
    },
  },
  i18n: {
    ...translations,
    PERFORMANCE_LABEL: s__('ExperimentTracking|Performance'),
    tabs: {
      metadata: s__('MlExperimentTracking|Overview'),
      candidates: s__('MlExperimentTracking|Runs'),
      performance: s__('MlExperimentTracking|Performance'),
    },
  },
  ROUTE_DETAILS,
  ROUTE_CANDIDATES,
  ROUTE_PERFORMANCE,
};
</script>

<template>
  <div>
    <title-area :title="experiment.name">
      <template #metadata-versions-count>
        <div class="detail-page-header-body gl-flex-wrap gl-gap-x-2" data-testid="metadata">
          <gl-icon name="issue-type-test-case" />
          <gl-sprintf :message="createdMessage">
            <template #timeAgo>
              <time-ago-tooltip :time="experiment.created_at" />
            </template>
            <template #author>
              <gl-link
                class="js-user-link gl-font-bold !gl-text-subtle"
                :href="experiment.user.path"
                :data-user-id="experiment.user.id"
              >
                <span>{{ experiment.user.name }}</span>
              </gl-link>
            </template>
          </gl-sprintf>
        </div>
      </template>
      <template #right-actions>
        <gl-button class="gl-mr-3" @click="downloadCsv">{{
          $options.i18n.DOWNLOAD_AS_CSV_LABEL
        }}</gl-button>
        <delete-button v-if="showDeleteButton" v-bind="deleteButtonInfo" />
      </template>
    </title-area>
    <gl-tabs :value="tabIndex">
      <gl-tab :title="$options.i18n.tabs.metadata" @click="goTo($options.ROUTE_DETAILS)" />
      <gl-tab @click="goTo($options.ROUTE_CANDIDATES)">
        <template #title>
          {{ $options.i18n.tabs.candidates }}
          <gl-badge class="gl-tab-counter-badge">{{ candidatesCount }}</gl-badge>
        </template>
      </gl-tab>
      <gl-tab :title="$options.i18n.PERFORMANCE_LABEL" @click="goTo($options.ROUTE_PERFORMANCE)" />
    </gl-tabs>

    <router-view
      :experiment="experiment"
      :candidates="candidates"
      :metric-names="metricNames"
      :param-names="paramNames"
      :page-info="pageInfo"
      :empty-state-svg-path="emptyStateSvgPath"
      :experiment-id="experimentGid"
    />
  </div>
</template>
