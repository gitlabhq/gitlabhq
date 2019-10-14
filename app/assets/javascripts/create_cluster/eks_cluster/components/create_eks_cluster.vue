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
  },
};
</script>
<template>
  <eks-cluster-configuration-form
    :gitlab-managed-cluster-help-path="gitlabManagedClusterHelpPath"
  />
</template>
