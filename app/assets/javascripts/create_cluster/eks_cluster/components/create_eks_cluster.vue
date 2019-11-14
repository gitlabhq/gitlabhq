<script>
import { mapState } from 'vuex';
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
    accountAndExternalIdsHelpPath: {
      type: String,
      required: true,
    },
    createRoleArnHelpPath: {
      type: String,
      required: true,
    },
    externalLinkIcon: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['hasCredentials']),
  },
};
</script>
<template>
  <div class="js-create-eks-cluster">
    <eks-cluster-configuration-form
      v-if="hasCredentials"
      :gitlab-managed-cluster-help-path="gitlabManagedClusterHelpPath"
      :kubernetes-integration-help-path="kubernetesIntegrationHelpPath"
      :external-link-icon="externalLinkIcon"
    />
    <service-credentials-form
      v-else
      :create-role-arn-help-path="createRoleArnHelpPath"
      :account-and-external-ids-help-path="accountAndExternalIdsHelpPath"
      :external-link-icon="externalLinkIcon"
    />
  </div>
</template>
