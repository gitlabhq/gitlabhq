<script>
import ServiceCredentialsForm from './service_credentials_form.vue';
import EksClusterConfigurationForm from './eks_cluster_configuration_form.vue';

export default {
  components: {
    ServiceCredentialsForm,
    EksClusterConfigurationForm,
  },
  props: {
    gitlabManagedClusterHelpPath: {
      type: String,
      required: true,
    },
    kubernetesIntegrationHelpPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="js-create-eks-cluster">
    <eks-cluster-configuration-form
      :gitlab-managed-cluster-help-path="gitlabManagedClusterHelpPath"
      :kubernetes-integration-help-path="kubernetesIntegrationHelpPath"
    />
  </div>
</template>
