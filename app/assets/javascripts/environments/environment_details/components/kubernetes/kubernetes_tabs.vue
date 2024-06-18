<script>
import { GlTabs, GlDrawer } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { k8sResourceType } from '~/environments/graphql/resolvers/kubernetes/constants';
import WorkloadDetails from '~/kubernetes_dashboard/components/workload_details.vue';
import KubernetesPods from './kubernetes_pods.vue';
import KubernetesServices from './kubernetes_services.vue';
import KubernetesSummary from './kubernetes_summary.vue';

const defaultTabs = [k8sResourceType.k8sPods, k8sResourceType.k8sServices];
const tabsWithSummary = ['summary', ...defaultTabs];

export default {
  components: {
    GlTabs,
    KubernetesPods,
    KubernetesServices,
    KubernetesSummary,
    GlDrawer,
    WorkloadDetails,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    configuration: {
      required: true,
      type: Object,
    },
    namespace: {
      required: true,
      type: String,
    },
    value: {
      required: true,
      type: String,
    },
    fluxKustomization: {
      required: false,
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      activeTabIndex: this.glFeatures.k8sTreeView
        ? tabsWithSummary.indexOf(this.value)
        : defaultTabs.indexOf(this.value),
      selectedItem: {},
      showDetailsDrawer: false,
    };
  },
  computed: {
    drawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    renderTreeView() {
      return this.glFeatures.k8sTreeView;
    },
    tabs() {
      return this.renderTreeView ? tabsWithSummary : defaultTabs;
    },
  },
  watch: {
    activeTabIndex(newValue) {
      this.$emit('input', this.tabs[newValue]);
    },
  },
  methods: {
    showResourceDetails(item) {
      this.selectedItem = item;
      this.showDetailsDrawer = true;
    },
    closeDetailsDrawer() {
      this.showDetailsDrawer = false;
    },
  },
  DRAWER_Z_INDEX,
};
</script>
<template>
  <div>
    <gl-tabs v-model="activeTabIndex">
      <kubernetes-summary
        v-if="renderTreeView"
        :flux-kustomization="fluxKustomization"
        :namespace="namespace"
        :configuration="configuration"
      />

      <kubernetes-pods
        :namespace="namespace"
        :configuration="configuration"
        @loading="$emit('loading', $event)"
        @update-failed-state="$emit('update-failed-state', $event)"
        @cluster-error="$emit('cluster-error', $event)"
        @show-resource-details="showResourceDetails"
        @remove-selection="closeDetailsDrawer"
      />

      <kubernetes-services
        :namespace="namespace"
        :configuration="configuration"
        @cluster-error="$emit('cluster-error', $event)"
        @show-resource-details="showResourceDetails"
        @remove-selection="closeDetailsDrawer"
      />
    </gl-tabs>

    <gl-drawer
      :open="showDetailsDrawer"
      :header-height="drawerHeaderHeight"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="closeDetailsDrawer"
    >
      <template #title>
        <h4 class="gl-font-bold gl-font-size-h2 gl-m-0 gl-break-anywhere">
          {{ selectedItem.name }}
        </h4>
      </template>
      <template #default>
        <workload-details :item="selectedItem" />
      </template>
    </gl-drawer>
  </div>
</template>
