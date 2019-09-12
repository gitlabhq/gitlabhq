<script>
import ServiceCredentialsForm from './service_credentials_form.vue';
import EksClusterConfigurationForm from './eks_cluster_configuration_form.vue';

export default {
  components: {
    ServiceCredentialsForm,
    EksClusterConfigurationForm,
  },
};
</script>
<template>
  <eks-cluster-configuration-form />
</template>
