<script>
import k8sConnectionStatusQuery from '~/environments/graphql/queries/k8s_connection_status.query.graphql';
import reconnectToClusterMutation from '~/environments/graphql/mutations/reconnect_to_cluster.mutation.graphql';
import { connectionStatus } from '~/environments/graphql/resolvers/kubernetes/constants';
import KubernetesConnectionStatusBadge from '~/environments/environment_details/components/kubernetes/kubernetes_connection_status_badge.vue';

export default {
  components: {
    KubernetesConnectionStatusBadge,
  },
  props: {
    configuration: {
      type: Object,
      required: true,
    },
    namespace: {
      type: String,
      required: true,
    },
    resourceTypeParam: {
      /*
        app/assets/javascripts/environments/graphql/typedefs.graphql#ResourceTypeParam
      */
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  apollo: {
    k8sConnection: {
      query: k8sConnectionStatusQuery,
      variables() {
        return {
          configuration: this.configuration,
          namespace: this.namespace,
        };
      },
      error(error) {
        this.$emit('error', error);
      },
    },
  },
  data() {
    return {
      k8sConnection: {},
    };
  },
  computed: {
    resourceType() {
      return this.resourceTypeParam.resourceType;
    },
    k8sResourceConnectionStatus() {
      const k8sResource = this.k8sConnection?.[this.resourceType];
      return k8sResource?.connectionStatus || connectionStatus.connecting;
    },
    connectionProps() {
      return {
        connectionStatus: this.k8sResourceConnectionStatus,
        reconnect: this.reconnect,
      };
    },
  },
  methods: {
    async reconnect() {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: reconnectToClusterMutation,
          variables: {
            configuration: this.configuration,
            namespace: this.namespace,
            resourceTypeParam: this.resourceTypeParam,
          },
        });
        const { errors } = data.reconnectToCluster;
        if (errors.length > 0) {
          this.$emit('error', errors[0]);
        }
      } catch (error) {
        this.$emit('error', error);
      }
    },
  },
};
</script>
<template>
  <div>
    <slot :connection-props="connectionProps">
      <kubernetes-connection-status-badge
        :popover-id="resourceType"
        :connection-status="k8sResourceConnectionStatus"
        @reconnect="reconnect"
      />
    </slot>
  </div>
</template>
