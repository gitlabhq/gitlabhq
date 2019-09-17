<script>
import { sprintf, s__ } from '~/locale';

import ClusterFormDropdown from './cluster_form_dropdown.vue';

export default {
  components: {
    ClusterFormDropdown,
  },
  props: {
    roles: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    helpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Select the IAM Role to allow Amazon EKS and the Kubernetes control plane to manage AWS resources on your behalf. To use a new role name, first create one on %{startLink}Amazon Web Services%{endLink}.',
        ),
        {
          startLink:
            '<a href="https://console.aws.amazon.com/iam/home?#roles" target="_blank" rel="noopener noreferrer">',
          endLink: '</a>',
        },
        false,
      );
    },
  },
};
</script>
<template>
  <div>
    <cluster-form-dropdown
      field-id="eks-role-name"
      field-name="eks-role-name"
      :items="roles"
      :loading="loading"
      :loading-text="s__('ClusterIntegration|Loading IAM Roles')"
      :placeholder="s__('ClusterIntergation|Select role name')"
      :search-field-placeholder="s__('ClusterIntegration|Search IAM Roles')"
      :empty-text="s__('ClusterIntegration|No IAM Roles found')"
    />
    <p class="form-text text-muted" v-html="helpText"></p>
  </div>
</template>
