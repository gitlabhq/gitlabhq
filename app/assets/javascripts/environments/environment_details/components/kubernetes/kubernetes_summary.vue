<script>
import { isEmpty } from 'lodash';
import { GlTab, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import { fluxSyncStatus } from '~/environments/helpers/k8s_integration_helper';
import { DEPLOYMENT_KIND } from '~/environments/constants';
import { calculateDeploymentStatus } from '~/kubernetes_dashboard/helpers/k8s_integration_helper';
import k8sDeploymentsQuery from '~/environments/graphql/queries/k8s_deployments.query.graphql';
import KubernetesTreeItem from './kubernetes_tree_item.vue';

export default {
  components: {
    GlTab,
    GlAlert,
    KubernetesTreeItem,
  },
  i18n: {
    summaryTitle: s__('Environment|Summary'),
    treeView: s__('Environment|Tree view'),
  },
  props: {
    fluxKustomization: {
      required: true,
      type: Object,
    },
    configuration: {
      required: true,
      type: Object,
    },
    namespace: {
      required: true,
      type: String,
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    k8sDeployments: {
      query: k8sDeploymentsQuery,
      variables() {
        return {
          configuration: this.configuration,
          namespace: this.namespace,
        };
      },
      update(data) {
        return (
          data?.k8sDeployments?.map((deployment) => {
            return {
              name: deployment.metadata.name,
              status: calculateDeploymentStatus(deployment),
            };
          }) || []
        );
      },
      skip() {
        return !this.hasFluxKustomization;
      },
      error(err) {
        this.errorMessage = err?.message;
      },
    },
  },
  data() {
    return {
      errorMessage: '',
    };
  },
  computed: {
    hasFluxKustomization() {
      return !isEmpty(this.fluxKustomization);
    },
    fluxKustomizationStatus() {
      if (!this.fluxKustomization.conditions?.length) return '';

      return fluxSyncStatus({ conditions: this.fluxKustomization.conditions }).status;
    },
    fluxInventory() {
      return (
        this.fluxKustomization?.inventory?.map((item) => {
          const [namespace, name, group, kind] = item.id.split('_');
          return { namespace, name, group, kind };
        }) || []
      );
    },
    fluxInventoryDeployments() {
      // Returns all the deployments listed in the Inventory object of the Kustomization
      return this.fluxInventory?.filter((item) => item.kind === DEPLOYMENT_KIND);
    },
    fluxRelatedDeployments() {
      // Maps the deployment statuses to the existing list of the inventory deployments
      if (!this.k8sDeployments) {
        return this.fluxInventoryDeployments;
      }

      return this.fluxInventoryDeployments.map((deployment) => {
        const match = this.k8sDeployments.find((item) => {
          return item?.name === deployment.name;
        });
        return { ...deployment, status: match?.status };
      });
    },
  },
  methods: {
    isLast(index) {
      return index === this.fluxInventoryDeployments.length - 1;
    },
  },
};
</script>
<template>
  <gl-tab :title="$options.i18n.summaryTitle">
    <p class="gl-mt-3 gl-text-subtle">{{ $options.i18n.treeView }}</p>
    <gl-alert v-if="errorMessage" :dismissible="false" variant="danger" class="gl-mb-4">{{
      errorMessage
    }}</gl-alert>

    <div
      class="kubernetes-tree-view gl-flex gl-items-start gl-overflow-x-auto gl-overflow-y-hidden"
    >
      <kubernetes-tree-item
        v-if="hasFluxKustomization"
        :kind="fluxKustomization.kind"
        :name="fluxKustomization.metadata.name"
        :status="fluxKustomizationStatus"
      />

      <div v-if="fluxRelatedDeployments.length" class="gl-ml-6" data-testid="related-deployments">
        <div
          v-for="(deployment, index) of fluxRelatedDeployments"
          :key="deployment.name"
          class="gl-relative"
        >
          <div
            class="connector gl-absolute gl-right-1/2 gl-top-1/2 gl-z-0 gl-border-1 gl-border-strong gl-border-t-solid"
            :class="{
              'gl-border-l-solid': !isLast(index),
            }"
          ></div>
          <kubernetes-tree-item
            :kind="deployment.kind"
            :name="deployment.name"
            :status="deployment.status"
            class="gl-mb-4"
          />
        </div>
      </div>
    </div>
  </gl-tab>
</template>
