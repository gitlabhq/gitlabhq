<script>
import { createNamespacedHelpers, mapState, mapActions } from 'vuex';
import { sprintf, s__ } from '~/locale';
import _ from 'underscore';
import { GlFormInput, GlFormCheckbox } from '@gitlab/ui';
import ClusterFormDropdown from './cluster_form_dropdown.vue';
import { KUBERNETES_VERSIONS } from '../constants';
import LoadingButton from '~/vue_shared/components/loading_button.vue';

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
const {
  mapState: mapInstanceTypesState,
  mapActions: mapInstanceTypesActions,
} = createNamespacedHelpers('instanceTypes');

export default {
  components: {
    ClusterFormDropdown,
    GlFormInput,
    GlFormCheckbox,
    LoadingButton,
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
    externalLinkIcon: {
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
      'selectedInstanceType',
      'nodeCount',
      'gitlabManagedCluster',
      'isCreatingCluster',
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
    ...mapInstanceTypesState({
      instanceTypes: 'items',
      isLoadingInstanceTypes: 'isLoadingItems',
      loadingInstanceTypesError: 'loadingItemsError',
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
    createClusterButtonDisabled() {
      return (
        !this.clusterName ||
        !this.environmentScope ||
        !this.kubernetesVersion ||
        !this.selectedRegion ||
        !this.selectedKeyPair ||
        !this.selectedVpc ||
        !this.selectedSubnet ||
        !this.selectedRole ||
        !this.selectedSecurityGroup ||
        !this.selectedInstanceType ||
        !this.nodeCount ||
        this.isCreatingCluster
      );
    },
    createClusterButtonLabel() {
      return this.isCreatingCluster
        ? s__('ClusterIntegration|Creating Kubernetes cluster')
        : s__('ClusterIntegration|Create Kubernetes cluster');
    },
    kubernetesIntegrationHelpText() {
      const escapedUrl = _.escape(this.kubernetesIntegrationHelpPath);

      return sprintf(
        s__(
          'ClusterIntegration|Read our %{link_start}help page%{link_end} on Kubernetes cluster integration.',
        ),
        {
          link_start: `<a href="${escapedUrl}" target="_blank" rel="noopener noreferrer">`,
          link_end: '</a>',
        },
        false,
      );
    },
    roleDropdownHelpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Select the IAM Role to allow Amazon EKS and the Kubernetes control plane to manage AWS resources on your behalf. To use a new role name, first create one on %{startLink}Amazon Web Services %{externalLinkIcon} %{endLink}.',
        ),
        {
          startLink:
            '<a href="https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html#role-create" target="_blank" rel="noopener noreferrer">',
          externalLinkIcon: this.externalLinkIcon,
          endLink: '</a>',
        },
        false,
      );
    },
    regionsDropdownHelpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Learn more about %{startLink}Regions %{externalLinkIcon}%{endLink}.',
        ),
        {
          startLink:
            '<a href="https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/" target="_blank" rel="noopener noreferrer">',
          externalLinkIcon: this.externalLinkIcon,
          endLink: '</a>',
        },
        false,
      );
    },
    keyPairDropdownHelpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Select the key pair name that will be used to create EC2 nodes. To use a new key pair name, first create one on %{startLink}Amazon Web Services %{externalLinkIcon} %{endLink}.',
        ),
        {
          startLink:
            '<a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair" target="_blank" rel="noopener noreferrer">',
          externalLinkIcon: this.externalLinkIcon,
          endLink: '</a>',
        },
        false,
      );
    },
    vpcDropdownHelpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Select a VPC to use for your EKS Cluster resources. To use a new VPC, first create one on %{startLink}Amazon Web Services %{externalLinkIcon} %{endLink}.',
        ),
        {
          startLink:
            '<a href="https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html#vpc-create" target="_blank" rel="noopener noreferrer">',
          externalLinkIcon: this.externalLinkIcon,
          endLink: '</a>',
        },
        false,
      );
    },
    subnetDropdownHelpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Choose the %{startLink}subnets %{externalLinkIcon} %{endLink} in your VPC where your worker nodes will run.',
        ),
        {
          startLink:
            '<a href="https://console.aws.amazon.com/vpc/home?#subnets" target="_blank" rel="noopener noreferrer">',
          externalLinkIcon: this.externalLinkIcon,
          endLink: '</a>',
        },
        false,
      );
    },
    securityGroupDropdownHelpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Choose the %{startLink}security group %{externalLinkIcon} %{endLink} to apply to the EKS-managed Elastic Network Interfaces that are created in your worker node subnets.',
        ),
        {
          startLink:
            '<a href="https://console.aws.amazon.com/vpc/home?#securityGroups" target="_blank" rel="noopener noreferrer">',
          externalLinkIcon: this.externalLinkIcon,
          endLink: '</a>',
        },
        false,
      );
    },
    instanceTypesDropdownHelpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Choose the worker node %{startLink}instance type %{externalLinkIcon} %{endLink}.',
        ),
        {
          startLink:
            '<a href="https://aws.amazon.com/ec2/instance-types" target="_blank" rel="noopener noreferrer">',
          externalLinkIcon: this.externalLinkIcon,
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
    this.fetchInstanceTypes();
  },
  methods: {
    ...mapActions([
      'createCluster',
      'signOut',
      'setClusterName',
      'setEnvironmentScope',
      'setKubernetesVersion',
      'setRegion',
      'setVpc',
      'setSubnet',
      'setRole',
      'setKeyPair',
      'setSecurityGroup',
      'setInstanceType',
      'setNodeCount',
      'setGitlabManagedCluster',
    ]),
    ...mapRegionsActions({ fetchRegions: 'fetchItems' }),
    ...mapVpcActions({ fetchVpcs: 'fetchItems' }),
    ...mapSubnetActions({ fetchSubnets: 'fetchItems' }),
    ...mapRolesActions({ fetchRoles: 'fetchItems' }),
    ...mapKeyPairsActions({ fetchKeyPairs: 'fetchItems' }),
    ...mapSecurityGroupsActions({ fetchSecurityGroups: 'fetchItems' }),
    ...mapInstanceTypesActions({ fetchInstanceTypes: 'fetchItems' }),
    setRegionAndFetchVpcsAndKeyPairs(region) {
      this.setRegion({ region });
      this.setVpc({ vpc: null });
      this.setKeyPair({ keyPair: null });
      this.setSubnet({ subnet: null });
      this.setSecurityGroup({ securityGroup: null });
      this.fetchVpcs({ region });
      this.fetchKeyPairs({ region });
    },
    setVpcAndFetchSubnets(vpc) {
      this.setVpc({ vpc });
      this.setSubnet({ subnet: null });
      this.setSecurityGroup({ securityGroup: null });
      this.fetchSubnets({ vpc, region: this.selectedRegion });
      this.fetchSecurityGroups({ vpc, region: this.selectedRegion });
    },
  },
};
</script>
<template>
  <form name="eks-cluster-configuration-form">
    <h2>
      {{ s__('ClusterIntegration|Enter the details for your Amazon EKS Kubernetes cluster') }}
    </h2>
    <div class="mb-3" v-html="kubernetesIntegrationHelpText"></div>
    <div class="mb-3">
      <button class="btn btn-link js-sign-out" @click.prevent="signOut()">
        {{ s__('ClusterIntegration|Select a different AWS role') }}
      </button>
    </div>
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
        :value="selectedRole"
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
      <cluster-form-dropdown
        field-id="eks-region"
        field-name="eks-region"
        :value="selectedRegion"
        :items="regions"
        :loading="isLoadingRegions"
        :loading-text="s__('ClusterIntegration|Loading Regions')"
        :placeholder="s__('ClusterIntergation|Select a region')"
        :search-field-placeholder="s__('ClusterIntegration|Search regions')"
        :empty-text="s__('ClusterIntegration|No region found')"
        :has-errors="Boolean(loadingRegionsError)"
        :error-message="s__('ClusterIntegration|Could not load regions from your AWS account')"
        @input="setRegionAndFetchVpcsAndKeyPairs($event)"
      />
      <p class="form-text text-muted" v-html="regionsDropdownHelpText"></p>
    </div>
    <div class="form-group">
      <label class="label-bold" for="eks-key-pair">{{
        s__('ClusterIntegration|Key pair name')
      }}</label>
      <cluster-form-dropdown
        field-id="eks-key-pair"
        field-name="eks-key-pair"
        :value="selectedKeyPair"
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
        :value="selectedVpc"
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
      <label class="label-bold" for="eks-role">{{ s__('ClusterIntegration|Subnets') }}</label>
      <cluster-form-dropdown
        field-id="eks-subnet"
        field-name="eks-subnet"
        multiple
        :value="selectedSubnet"
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
        s__('ClusterIntegration|Security group')
      }}</label>
      <cluster-form-dropdown
        field-id="eks-security-group"
        field-name="eks-security-group"
        :value="selectedSecurityGroup"
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
      <label class="label-bold" for="eks-instance-type">{{
        s__('ClusterIntegration|Instance type')
      }}</label>
      <cluster-form-dropdown
        field-id="eks-instance-type"
        field-name="eks-instance-type"
        :value="selectedInstanceType"
        :items="instanceTypes"
        :loading="isLoadingInstanceTypes"
        :loading-text="s__('ClusterIntegration|Loading instance types')"
        :placeholder="s__('ClusterIntergation|Select an instance type')"
        :search-field-placeholder="s__('ClusterIntegration|Search instance types')"
        :empty-text="s__('ClusterIntegration|No instance type found')"
        :has-errors="Boolean(loadingInstanceTypesError)"
        :error-message="s__('ClusterIntegration|Could not load instance types')"
        @input="setInstanceType({ instanceType: $event })"
      />
      <p class="form-text text-muted" v-html="instanceTypesDropdownHelpText"></p>
    </div>
    <div class="form-group">
      <label class="label-bold" for="eks-node-count">{{
        s__('ClusterIntegration|Number of nodes')
      }}</label>
      <gl-form-input
        id="eks-node-count"
        type="number"
        min="1"
        step="1"
        :value="nodeCount"
        @input="setNodeCount({ nodeCount: $event })"
      />
    </div>
    <div class="form-group">
      <gl-form-checkbox
        :checked="gitlabManagedCluster"
        @input="setGitlabManagedCluster({ gitlabManagedCluster: $event })"
        >{{ s__('ClusterIntegration|GitLab-managed cluster') }}</gl-form-checkbox
      >
      <p class="form-text text-muted" v-html="gitlabManagedHelpText"></p>
    </div>
    <div class="form-group">
      <loading-button
        class="js-create-cluster btn-success"
        :disabled="createClusterButtonDisabled"
        :loading="isCreatingCluster"
        :label="createClusterButtonLabel"
        @click="createCluster()"
      />
    </div>
  </form>
</template>
