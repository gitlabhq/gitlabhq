<script>
import { createNamespacedHelpers, mapState, mapActions } from 'vuex';
import { sprintf, s__ } from '~/locale';
import _ from 'underscore';
import { GlFormInput, GlFormCheckbox } from '@gitlab/ui';
import ClusterFormDropdown from './cluster_form_dropdown.vue';
import RegionDropdown from './region_dropdown.vue';
import { KUBERNETES_VERSIONS } from '../constants';

const { mapState: mapRolesState, mapActions: mapRolesActions } = createNamespacedHelpers('roles');
const { mapState: mapRegionsState, mapActions: mapRegionsActions } = createNamespacedHelpers(
  'regions',
);
const { mapState: mapKeyPairsState, mapActions: mapKeyPairsActions } = createNamespacedHelpers(
  'keyPairs',
);
const { mapState: mapVpcsState, mapActions: mapVpcActions } = createNamespacedHelpers('vpcs');
const { mapState: mapSubnetsState, mapActions: mapSubnetActions } = createNamespacedHelpers(
  'subnets',
);
const {
  mapState: mapSecurityGroupsState,
  mapActions: mapSecurityGroupsActions,
} = createNamespacedHelpers('securityGroups');

export default {
  components: {
    ClusterFormDropdown,
    RegionDropdown,
    GlFormInput,
    GlFormCheckbox,
  },
  props: {
    gitlabManagedClusterHelpPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'clusterName',
      'environmentScope',
      'kubernetesVersion',
      'selectedRegion',
      'selectedKeyPair',
      'selectedVpc',
      'selectedSubnet',
      'selectedRole',
      'selectedSecurityGroup',
      'gitlabManagedCluster',
    ]),
    ...mapRolesState({
      roles: 'items',
      isLoadingRoles: 'isLoadingItems',
      loadingRolesError: 'loadingItemsError',
    }),
    ...mapRegionsState({
      regions: 'items',
      isLoadingRegions: 'isLoadingItems',
      loadingRegionsError: 'loadingItemsError',
    }),
    ...mapKeyPairsState({
      keyPairs: 'items',
      isLoadingKeyPairs: 'isLoadingItems',
      loadingKeyPairsError: 'loadingItemsError',
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
    ...mapSecurityGroupsState({
      securityGroups: 'items',
      isLoadingSecurityGroups: 'isLoadingItems',
      loadingSecurityGroupsError: 'loadingItemsError',
    }),
    kubernetesVersions() {
      return KUBERNETES_VERSIONS;
    },
    vpcDropdownDisabled() {
      return !this.selectedRegion;
    },
    keyPairDropdownDisabled() {
      return !this.selectedRegion;
    },
    subnetDropdownDisabled() {
      return !this.selectedVpc;
    },
    securityGroupDropdownDisabled() {
      return !this.selectedVpc;
    },
    roleDropdownHelpText() {
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
    keyPairDropdownHelpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Select the key pair name that will be used to create EC2 nodes. To use a new key pair name, first create one on %{startLink}Amazon Web Services%{endLink}.',
        ),
        {
          startLink:
            '<a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair" target="_blank" rel="noopener noreferrer">',
          endLink: '</a>',
        },
        false,
      );
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
    securityGroupDropdownHelpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Choose the %{startLink}security groups%{endLink} to apply to the EKS-managed Elastic Network Interfaces that are created in your worker node subnets.',
        ),
        {
          startLink:
            '<a href="https://console.aws.amazon.com/vpc/home?#securityGroups" target="_blank" rel="noopener noreferrer">',
          endLink: '</a>',
        },
        false,
      );
    },
    gitlabManagedHelpText() {
      const escapedUrl = _.escape(this.gitlabManagedClusterHelpPath);

      return sprintf(
        s__(
          'ClusterIntegration|Allow GitLab to manage namespace and service accounts for this cluster. %{startLink}More information%{endLink}',
        ),
        {
          startLink: `<a href="${escapedUrl}" target="_blank" rel="noopener noreferrer">`,
          endLink: '</a>',
        },
        false,
      );
    },
  },
  mounted() {
    this.fetchRegions();
    this.fetchRoles();
  },
  methods: {
    ...mapActions([
      'setClusterName',
      'setEnvironmentScope',
      'setKubernetesVersion',
      'setRegion',
      'setVpc',
      'setSubnet',
      'setRole',
      'setKeyPair',
      'setSecurityGroup',
      'setGitlabManagedCluster',
    ]),
    ...mapRegionsActions({ fetchRegions: 'fetchItems' }),
    ...mapVpcActions({ fetchVpcs: 'fetchItems' }),
    ...mapSubnetActions({ fetchSubnets: 'fetchItems' }),
    ...mapRolesActions({ fetchRoles: 'fetchItems' }),
    ...mapKeyPairsActions({ fetchKeyPairs: 'fetchItems' }),
    ...mapSecurityGroupsActions({ fetchSecurityGroups: 'fetchItems' }),
    setRegionAndFetchVpcsAndKeyPairs(region) {
      this.setRegion({ region });
      this.fetchVpcs({ region });
      this.fetchKeyPairs({ region });
    },
    setVpcAndFetchSubnets(vpc) {
      this.setVpc({ vpc });
      this.fetchSubnets({ vpc });
      this.fetchSecurityGroups({ vpc });
    },
  },
};
</script>
<template>
  <form name="eks-cluster-configuration-form">
    <div class="form-group">
      <label class="label-bold" for="eks-cluster-name">{{
        s__('ClusterIntegration|Kubernetes cluster name')
      }}</label>
      <gl-form-input
        id="eks-cluster-name"
        :value="clusterName"
        @input="setClusterName({ clusterName: $event })"
      />
    </div>
    <div class="form-group">
      <label class="label-bold" for="eks-environment-scope">{{
        s__('ClusterIntegration|Environment scope')
      }}</label>
      <gl-form-input
        id="eks-environment-scope"
        :value="environmentScope"
        @input="setEnvironmentScope({ environmentScope: $event })"
      />
    </div>
    <div class="form-group">
      <label class="label-bold" for="eks-kubernetes-version">{{
        s__('ClusterIntegration|Kubernetes version')
      }}</label>
      <cluster-form-dropdown
        field-id="eks-kubernetes-version"
        field-name="eks-kubernetes-version"
        :value="kubernetesVersion"
        :items="kubernetesVersions"
        :empty-text="s__('ClusterIntegration|Kubernetes version not found')"
        @input="setKubernetesVersion({ kubernetesVersion: $event })"
      />
      <p class="form-text text-muted" v-html="roleDropdownHelpText"></p>
    </div>
    <div class="form-group">
      <label class="label-bold" for="eks-role">{{ s__('ClusterIntegration|Role name') }}</label>
      <cluster-form-dropdown
        field-id="eks-role"
        field-name="eks-role"
        :input="selectedRole"
        :items="roles"
        :loading="isLoadingRoles"
        :loading-text="s__('ClusterIntegration|Loading IAM Roles')"
        :placeholder="s__('ClusterIntergation|Select role name')"
        :search-field-placeholder="s__('ClusterIntegration|Search IAM Roles')"
        :empty-text="s__('ClusterIntegration|No IAM Roles found')"
        :has-errors="Boolean(loadingRolesError)"
        :error-message="s__('ClusterIntegration|Could not load IAM roles')"
        @input="setRole({ role: $event })"
      />
      <p class="form-text text-muted" v-html="roleDropdownHelpText"></p>
    </div>
    <div class="form-group">
      <label class="label-bold" for="eks-role">{{ s__('ClusterIntegration|Region') }}</label>
      <region-dropdown
        :value="selectedRegion"
        :regions="regions"
        :error="loadingRegionsError"
        :loading="isLoadingRegions"
        @input="setRegionAndFetchVpcsAndKeyPairs($event)"
      />
    </div>
    <div class="form-group">
      <label class="label-bold" for="eks-key-pair">{{
        s__('ClusterIntegration|Key pair name')
      }}</label>
      <cluster-form-dropdown
        field-id="eks-key-pair"
        field-name="eks-key-pair"
        :input="selectedKeyPair"
        :items="keyPairs"
        :disabled="keyPairDropdownDisabled"
        :disabled-text="s__('ClusterIntegration|Select a region to choose a Key Pair')"
        :loading="isLoadingKeyPairs"
        :loading-text="s__('ClusterIntegration|Loading Key Pairs')"
        :placeholder="s__('ClusterIntergation|Select key pair')"
        :search-field-placeholder="s__('ClusterIntegration|Search Key Pairs')"
        :empty-text="s__('ClusterIntegration|No Key Pairs found')"
        :has-errors="Boolean(loadingKeyPairsError)"
        :error-message="s__('ClusterIntegration|Could not load Key Pairs')"
        @input="setKeyPair({ keyPair: $event })"
      />
      <p class="form-text text-muted" v-html="keyPairDropdownHelpText"></p>
    </div>
    <div class="form-group">
      <label class="label-bold" for="eks-vpc">{{ s__('ClusterIntegration|VPC') }}</label>
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
        :has-errors="Boolean(loadingVpcsError)"
        :error-message="s__('ClusterIntegration|Could not load VPCs for the selected region')"
        @input="setVpcAndFetchSubnets($event)"
      />
      <p class="form-text text-muted" v-html="vpcDropdownHelpText"></p>
    </div>
    <div class="form-group">
      <label class="label-bold" for="eks-role">{{ s__('ClusterIntegration|Subnet') }}</label>
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
        :has-errors="Boolean(loadingSubnetsError)"
        :error-message="s__('ClusterIntegration|Could not load subnets for the selected VPC')"
        @input="setSubnet({ subnet: $event })"
      />
      <p class="form-text text-muted" v-html="subnetDropdownHelpText"></p>
    </div>
    <div class="form-group">
      <label class="label-bold" for="eks-security-group">{{
        s__('ClusterIntegration|Security groups')
      }}</label>
      <cluster-form-dropdown
        field-id="eks-security-group"
        field-name="eks-security-group"
        :input="selectedSecurityGroup"
        :items="securityGroups"
        :loading="isLoadingSecurityGroups"
        :disabled="securityGroupDropdownDisabled"
        :disabled-text="s__('ClusterIntegration|Select a VPC to choose a security group')"
        :loading-text="s__('ClusterIntegration|Loading security groups')"
        :placeholder="s__('ClusterIntergation|Select a security group')"
        :search-field-placeholder="s__('ClusterIntegration|Search security groups')"
        :empty-text="s__('ClusterIntegration|No security group found')"
        :has-errors="Boolean(loadingSecurityGroupsError)"
        :error-message="
          s__('ClusterIntegration|Could not load security groups for the selected VPC')
        "
        @input="setSecurityGroup({ securityGroup: $event })"
      />
      <p class="form-text text-muted" v-html="securityGroupDropdownHelpText"></p>
    </div>
    <div class="form-group">
      <gl-form-checkbox
        :checked="gitlabManagedCluster"
        @input="setGitlabManagedCluster({ gitlabManagedCluster: $event })"
        >{{ s__('ClusterIntegration|GitLab-managed cluster') }}</gl-form-checkbox
      >
      <p class="form-text text-muted" v-html="gitlabManagedHelpText"></p>
    </div>
  </form>
</template>
