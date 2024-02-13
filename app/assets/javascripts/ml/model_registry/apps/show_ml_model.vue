<script>
import { GlTab, GlTabs, GlBadge } from '@gitlab/ui';
import VueRouter from 'vue-router';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { MODEL_ENTITIES } from '~/ml/model_registry/constants';
import ModelVersionList from '~/ml/model_registry/components/model_version_list.vue';
import CandidateList from '~/ml/model_registry/components/candidate_list.vue';
import ModelDetail from '~/ml/model_registry/components/model_detail.vue';
import * as i18n from '../translations';

const ROUTE_DETAILS = 'details';
const ROUTE_VERSIONS = 'versions';
const ROUTE_CANDIDATES = 'candidates';

const routes = [
  {
    path: '/',
    name: ROUTE_DETAILS,
    component: ModelDetail,
  },
  {
    path: '/versions',
    name: ROUTE_VERSIONS,
    component: ModelVersionList,
  },
  {
    path: '/candidates',
    name: ROUTE_CANDIDATES,
    component: CandidateList,
  },
  { path: '*', redirect: { name: ROUTE_DETAILS } },
];

export default {
  name: 'ShowMlModelApp',
  components: {
    TitleArea,
    GlTabs,
    GlTab,
    GlBadge,
    MetadataItem,
  },
  router: new VueRouter({
    routes,
  }),
  props: {
    model: {
      type: Object,
      required: true,
    },
  },
  computed: {
    versionCount() {
      return this.model.versionCount || 0;
    },
    candidateCount() {
      return this.model.candidateCount || 0;
    },
    tabIndex() {
      return routes.findIndex(({ name }) => name === this.$route.name);
    },
  },
  methods: {
    goTo(name) {
      if (name !== this.$route.name) {
        this.$router.push({ name });
      }
    },
  },
  i18n,
  modelVersionEntity: MODEL_ENTITIES.modelVersion,
  ROUTE_DETAILS,
  ROUTE_VERSIONS,
  ROUTE_CANDIDATES,
};
</script>

<template>
  <div>
    <title-area :title="model.name">
      <template #metadata-versions-count>
        <metadata-item
          icon="machine-learning"
          :text="$options.i18n.versionsCountLabel(model.versionCount)"
        />
      </template>

      <template #sub-header>
        {{ model.description }}
      </template>
    </title-area>

    <gl-tabs class="gl-mt-4" :value="tabIndex">
      <gl-tab
        :title="$options.i18n.MODEL_DETAILS_TAB_LABEL"
        @click="goTo($options.ROUTE_DETAILS)"
      />
      <gl-tab @click="goTo($options.ROUTE_VERSIONS)">
        <template #title>
          {{ $options.i18n.MODEL_OTHER_VERSIONS_TAB_LABEL }}
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ versionCount }}</gl-badge>
        </template>
      </gl-tab>
      <gl-tab @click="goTo($options.ROUTE_CANDIDATES)">
        <template #title>
          {{ $options.i18n.MODEL_CANDIDATES_TAB_LABEL }}
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ candidateCount }}</gl-badge>
        </template>
      </gl-tab>

      <router-view :model-id="model.id" :model="model" />
    </gl-tabs>
  </div>
</template>
