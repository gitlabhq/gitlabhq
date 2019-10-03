<script>
import { createNamespacedHelpers, mapState, mapActions } from 'vuex';
import { sprintf, s__ } from '~/locale';
import ClusterFormDropdown from './cluster_form_dropdown.vue';
import RegionDropdown from './region_dropdown.vue';
import RoleNameDropdown from './role_name_dropdown.vue';
import SecurityGroupDropdown from './security_group_dropdown.vue';

const { mapState: mapRegionsState, mapActions: mapRegionsActions } = createNamespacedHelpers(
  'regions',
);
const { mapState: mapVpcsState, mapActions: mapVpcActions } = createNamespacedHelpers('vpcs');
const { mapState: mapSubnetsState, mapActions: mapSubnetActions } = createNamespacedHelpers(
  'subnets',
);

export default {
  components: {
    ClusterFormDropdown,
    RegionDropdown,
    RoleNameDropdown,
    SecurityGroupDropdown,
  },
  computed: {
    ...mapState(['selectedRegion', 'selectedVpc', 'selectedSubnet']),
    ...mapRegionsState({
      regions: 'items',
      isLoadingRegions: 'isLoadingItems',
      loadingRegionsError: 'loadingItemsError',
    }),
    ...mapVpcsState({
      vpcs: 'items',
      isLoadingVpcs: 'isLoadingItems',
      loadingVpcsError: 'loadingItemsError',
    }),
    ...mapSubnetsState({
      subnets: 'items',
      isLoadingSubnets: 'isLoadingItems',
      loadingSubnetsError: 'loadingItemsError',
    }),
    vpcDropdownDisabled() {
      return !this.selectedRegion;
    },
    subnetDropdownDisabled() {
      return !this.selectedVpc;
    },
    vpcDropdownHelpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Select a VPC to use for your EKS Cluster resources. To use a new VPC, first create one on %{startLink}Amazon Web Services%{endLink}.',
        ),
        {
          startLink:
            '<a href="https://console.aws.amazon.com/vpc/home?#vpc" target="_blank" rel="noopener noreferrer">',
          endLink: '</a>',
        },
        false,
      );
    },
    subnetDropdownHelpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Choose the %{startLink}subnets%{endLink} in your VPC where your worker nodes will run.',
        ),
        {
          startLink:
            '<a href="https://console.aws.amazon.com/vpc/home?#subnets" target="_blank" rel="noopener noreferrer">',
          endLink: '</a>',
        },
        false,
      );
    },
  },
  mounted() {
    this.fetchRegions();
  },
  methods: {
    ...mapActions(['setRegion', 'setVpc', 'setSubnet']),
    ...mapRegionsActions({ fetchRegions: 'fetchItems' }),
    ...mapVpcActions({ fetchVpcs: 'fetchItems' }),
    ...mapSubnetActions({ fetchSubnets: 'fetchItems' }),
    setRegionAndFetchVpcs(region) {
      this.setRegion({ region });
      this.fetchVpcs({ region });
    },
    setVpcAndFetchSubnets(vpc) {
      this.setVpc({ vpc });
      this.fetchSubnets({ vpc });
    },
  },
};
</script>
<template>
  <form name="eks-cluster-configuration-form">
    <div class="form-group">
      <label class="label-bold" name="role" for="eks-role">{{
        s__('ClusterIntegration|Role name')
      }}</label>
      <role-name-dropdown />
    </div>
    <div class="form-group">
      <label class="label-bold" name="role" for="eks-role">{{
        s__('ClusterIntegration|Region')
      }}</label>
      <region-dropdown
        :value="selectedRegion"
        :regions="regions"
        :error="loadingRegionsError"
        :loading="isLoadingRegions"
        @input="setRegionAndFetchVpcs($event)"
      />
    </div>
    <div class="form-group">
      <label class="label-bold" name="eks-vpc" for="eks-vpc">{{
        s__('ClusterIntegration|VPC')
      }}</label>
      <cluster-form-dropdown
        field-id="eks-vpc"
        field-name="eks-vpc"
        :input="selectedVpc"
        :items="vpcs"
        :loading="isLoadingVpcs"
        :disabled="vpcDropdownDisabled"
        :disabled-text="s__('ClusterIntegration|Select a region to choose a VPC')"
        :loading-text="s__('ClusterIntegration|Loading VPCs')"
        :placeholder="s__('ClusterIntergation|Select a VPC')"
        :search-field-placeholder="s__('ClusterIntegration|Search VPCs')"
        :empty-text="s__('ClusterIntegration|No VPCs found')"
        :has-errors="loadingVpcsError"
        :error-message="s__('ClusterIntegration|Could not load VPCs for the selected region')"
        @input="setVpcAndFetchSubnets($event)"
      />
      <p class="form-text text-muted" v-html="vpcDropdownHelpText"></p>
    </div>
    <div class="form-group">
      <label class="label-bold" name="eks-subnet" for="eks-subnet">{{
        s__('ClusterIntegration|Subnet')
      }}</label>
      <cluster-form-dropdown
        field-id="eks-subnet"
        field-name="eks-subnet"
        :input="selectedSubnet"
        :items="subnets"
        :loading="isLoadingSubnets"
        :disabled="subnetDropdownDisabled"
        :disabled-text="s__('ClusterIntegration|Select a VPC to choose a subnet')"
        :loading-text="s__('ClusterIntegration|Loading subnets')"
        :placeholder="s__('ClusterIntergation|Select a subnet')"
        :search-field-placeholder="s__('ClusterIntegration|Search subnets')"
        :empty-text="s__('ClusterIntegration|No subnet found')"
        :has-errors="loadingSubnetsError"
        :error-message="s__('ClusterIntegration|Could not load subnets for the selected VPC')"
        @input="setSubnet({ subnet: $event })"
      />
      <p class="form-text text-muted" v-html="subnetDropdownHelpText"></p>
    </div>
  </form>
</template>
