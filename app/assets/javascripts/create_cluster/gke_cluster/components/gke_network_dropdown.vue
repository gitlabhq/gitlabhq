<script>
import { createNamespacedHelpers, mapState, mapGetters, mapActions } from 'vuex';

import ClusterFormDropdown from '~/create_cluster/components/cluster_form_dropdown.vue';

const { mapState: mapDropdownState } = createNamespacedHelpers('networks');
const { mapActions: mapSubnetworkActions } = createNamespacedHelpers('subnetworks');

export default {
  components: {
    ClusterFormDropdown,
  },
  props: {
    fieldName: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['selectedNetwork']),
    ...mapDropdownState(['items', 'isLoadingItems', 'loadingItemsError']),
    ...mapGetters(['hasZone', 'projectId', 'region']),
  },
  methods: {
    ...mapActions(['setNetwork', 'setSubnetwork']),
    ...mapSubnetworkActions({ fetchSubnetworks: 'fetchItems' }),
    setNetworkAndFetchSubnetworks(network) {
      const { projectId: project, region } = this;

      this.setSubnetwork('');
      this.setNetwork(network);
      this.fetchSubnetworks({ project, region, network: network.selfLink });
    },
  },
};
</script>
<template>
  <cluster-form-dropdown
    :field-name="fieldName"
    :value="selectedNetwork"
    :items="items"
    :disabled="!hasZone"
    :loading="isLoadingItems"
    :has-errors="Boolean(loadingItemsError)"
    :loading-text="s__('ClusterIntegration|Loading networks')"
    :placeholder="s__('ClusterIntergation|Select a network')"
    :search-field-placeholder="s__('ClusterIntegration|Search networks')"
    :empty-text="s__('ClusterIntegration|No networks found')"
    :error-message="s__('ClusterIntegration|Could not load networks')"
    :disabled-text="s__('ClusterIntegration|Select a zone to choose a network')"
    @input="setNetworkAndFetchSubnetworks"
  />
</template>
