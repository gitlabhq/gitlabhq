<script>
import { GlTabs, GlDrawer } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { k8sResourceType } from '~/environments/graphql/resolvers/kubernetes/constants';
import WorkloadDetails from '~/kubernetes_dashboard/components/workload_details.vue';
import KubernetesPods from './kubernetes_pods.vue';
import KubernetesServices from './kubernetes_services.vue';

const tabs = [k8sResourceType.k8sPods, k8sResourceType.k8sServices];

export default {
  components: {
    GlTabs,
    KubernetesPods,
    KubernetesServices,
    GlDrawer,
    WorkloadDetails,
  },

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
  },
  data() {
    return {
      activeTabIndex: tabs.indexOf(this.value),
      selectedItem: {},
      showDetailsDrawer: false,
    };
  },
  computed: {
    drawerHeaderHeight() {
      return getContentWrapperHeight();
    },
  },
  watch: {
    activeTabIndex(newValue) {
      this.$emit('input', tabs[newValue]);
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
        <h4 class="gl-font-weight-bold gl-font-size-h2 gl-m-0 gl-word-break-word">
          {{ selectedItem.name }}
        </h4>
      </template>
      <template #default>
        <workload-details :item="selectedItem" />
      </template>
    </gl-drawer>
  </div>
</template>
