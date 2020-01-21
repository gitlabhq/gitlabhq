<script>
import { createNamespacedHelpers, mapState, mapGetters, mapActions } from 'vuex';

import ClusterFormDropdown from '~/create_cluster/components/cluster_form_dropdown.vue';

const { mapState: mapDropdownState } = createNamespacedHelpers('subnetworks');

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
    ...mapState(['selectedSubnetwork']),
    ...mapDropdownState(['items', 'isLoadingItems', 'loadingItemsError']),
    ...mapGetters(['hasNetwork']),
  },
  methods: {
    ...mapActions(['setSubnetwork']),
  },
};
</script>
<template>
  <cluster-form-dropdown
    :field-name="fieldName"
    :value="selectedSubnetwork"
    :items="items"
    :disabled="!hasNetwork"
    :loading="isLoadingItems"
    :has-errors="Boolean(loadingItemsError)"
    :loading-text="s__('ClusterIntegration|Loading subnetworks')"
    :placeholder="s__('ClusterIntergation|Select a subnetwork')"
    :search-field-placeholder="s__('ClusterIntegration|Search subnetworks')"
    :empty-text="s__('ClusterIntegration|No subnetworks found')"
    :error-message="s__('ClusterIntegration|Could not load subnetworks')"
    :disabled-text="s__('ClusterIntegration|Select a network to choose a subnetwork')"
    @input="setSubnetwork"
  />
</template>
