<script>
import { sprintf, s__ } from '~/locale';

import ClusterFormDropdown from './cluster_form_dropdown.vue';

export default {
  components: {
    ClusterFormDropdown,
  },
  props: {
    regions: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    error: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    hasErrors() {
      return Boolean(this.error);
    },
    helpText() {
      return sprintf(
        s__('ClusterIntegration|Learn more about %{startLink}Regions%{endLink}.'),
        {
          startLink:
            '<a href="https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/" target="_blank" rel="noopener noreferrer">',
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
      field-id="eks-region"
      field-name="eks-region"
      :items="regions"
      :loading="loading"
      :loading-text="s__('ClusterIntegration|Loading Regions')"
      :placeholder="s__('ClusterIntergation|Select a region')"
      :search-field-placeholder="s__('ClusterIntegration|Search regions')"
      :empty-text="s__('ClusterIntegration|No region found')"
      :has-errors="hasErrors"
      :error-message="s__('ClusterIntegration|Could not load regions from your AWS account')"
      v-bind="$attrs"
      v-on="$listeners"
    />
    <p class="form-text text-muted" v-html="helpText"></p>
  </div>
</template>
