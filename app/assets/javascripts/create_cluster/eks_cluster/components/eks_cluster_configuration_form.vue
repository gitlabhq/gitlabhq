<script>
import {
  GlFormGroup,
  GlFormInput,
  GlFormCheckbox,
  GlIcon,
  GlLink,
  GlSprintf,
  GlButton,
} from '@gitlab/ui';
import { createNamespacedHelpers, mapState, mapActions, mapGetters } from 'vuex';
import ClusterFormDropdown from '~/create_cluster/components/cluster_form_dropdown.vue';
import { s__ } from '~/locale';
import { KUBERNETES_VERSIONS } from '../constants';

const { mapState: mapRolesState, mapActions: mapRolesActions } = createNamespacedHelpers('roles');
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
const { mapState: mapInstanceTypesState } = createNamespacedHelpers('instanceTypes');

export default {
  components: {
    ClusterFormDropdown,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlIcon,
    GlLink,
    GlSprintf,
    GlButton,
  },
  props: {
    gitlabManagedClusterHelpPath: {
      type: String,
      required: true,
    },
    namespacePerEnvironmentHelpPath: {
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
  i18n: {
    kubernetesIntegrationHelpText: s__(
      'ClusterIntegration|Read our %{linkStart}help page%{linkEnd} on Kubernetes cluster integration.',
    ),
    roleDropdownHelpText: s__(
      'ClusterIntegration|Your service role is distinct from the provision role used when authenticating. It will allow Amazon EKS and the Kubernetes control plane to manage AWS resources on your behalf. To use a new role, first create one on %{linkStart}Amazon Web Services%{linkEnd}.',
    ),
    roleDropdownHelpPath:
      'https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html#create-service-role',
    regionInputLabel: s__('ClusterIntegration|Cluster Region'),
    regionHelpText: s__(
      'ClusterIntegration|The region the new cluster will be created in. You must reauthenticate to change regions.',
    ),
    keyPairDropdownHelpText: s__(
      'ClusterIntegration|Select the key pair name that will be used to create EC2 nodes. To use a new key pair name, first create one on %{linkStart}Amazon Web Services%{linkEnd}.',
    ),
    keyPairDropdownHelpPath:
      'https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair',
    vpcDropdownHelpText: s__(
      'ClusterIntegration|Select a VPC to use for your EKS Cluster resources. To use a new VPC, first create one on %{linkStart}Amazon Web Services %{linkEnd}.',
    ),
    vpcDropdownHelpPath:
      'https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html#vpc-create',
    subnetDropdownHelpText: s__(
      'ClusterIntegration|Choose the %{linkStart}subnets %{linkEnd} in your VPC where your worker nodes will run.',
    ),
    subnetDropdownHelpPath: 'https://console.aws.amazon.com/vpc/home?#subnets',
    securityGroupDropdownHelpText: s__(
      'ClusterIntegration|Choose the %{linkStart}security group %{linkEnd} to apply to the EKS-managed Elastic Network Interfaces that are created in your worker node subnets.',
    ),
    securityGroupDropdownHelpPath: 'https://console.aws.amazon.com/vpc/home?#securityGroups',
    instanceTypesDropdownHelpText: s__(
      'ClusterIntegration|Choose the worker node %{linkStart}instance type%{linkEnd}.',
    ),
    instanceTypesDropdownHelpPath: 'https://aws.amazon.com/ec2/instance-types',
    gitlabManagedClusterHelpText: s__(
      'ClusterIntegration|Allow GitLab to manage namespace and service accounts for this cluster. %{linkStart}More information%{linkEnd}',
    ),
    namespacePerEnvironmentHelpText: s__(
      'ClusterIntegration|Deploy each environment to its own namespace. Otherwise, environments within a project share a project-wide namespace. Note that anyone who can trigger a deployment of a namespace can read its secrets. If modified, existing environments will use their current namespaces until the cluster cache is cleared. %{linkStart}More information%{linkEnd}',
    ),
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
      'namespacePerEnvironment',
      'isCreatingCluster',
    ]),
    ...mapGetters(['subnetValid']),
    ...mapRolesState({
      roles: 'items',
      isLoadingRoles: 'isLoadingItems',
      loadingRolesError: 'loadingItemsError',
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
        !this.subnetValid ||
        !this.selectedRole ||
        !this.selectedSecurityGroup ||
        !this.selectedInstanceType ||
        !this.nodeCount ||
        this.isCreatingCluster
      );
    },
    displaySubnetError() {
      return Boolean(this.loadingSubnetsError) || this.selectedSubnet?.length === 1;
    },
    createClusterButtonLabel() {
      return this.isCreatingCluster
        ? s__('ClusterIntegration|Creating Kubernetes cluster')
        : s__('ClusterIntegration|Create Kubernetes cluster');
    },
    subnetValidationErrorText() {
      if (this.loadingSubnetsError) {
        return s__('ClusterIntegration|Could not load subnets for the selected VPC');
      }

      return s__('ClusterIntegration|You should select at least two subnets');
    },
  },
  mounted() {
    this.fetchRoles();
    this.setRegionAndFetchVpcsAndKeyPairs();
  },
  methods: {
    ...mapActions([
      'createCluster',
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
      'setNamespacePerEnvironment',
    ]),
    ...mapVpcActions({ fetchVpcs: 'fetchItems' }),
    ...mapSubnetActions({ fetchSubnets: 'fetchItems' }),
    ...mapRolesActions({ fetchRoles: 'fetchItems' }),
    ...mapKeyPairsActions({ fetchKeyPairs: 'fetchItems' }),
    ...mapSecurityGroupsActions({ fetchSecurityGroups: 'fetchItems' }),
    setRegionAndFetchVpcsAndKeyPairs() {
      this.setVpc({ vpc: null });
      this.setKeyPair({ keyPair: null });
      this.setSubnet({ subnet: [] });
      this.setSecurityGroup({ securityGroup: null });
      this.fetchVpcs({ region: this.selectedRegion });
      this.fetchKeyPairs({ region: this.selectedRegion });
    },
    setVpcAndFetchSubnets(vpc) {
      this.setVpc({ vpc });
      this.setSubnet({ subnet: [] });
      this.setSecurityGroup({ securityGroup: null });
      this.fetchSubnets({ vpc, region: this.selectedRegion });
      this.fetchSecurityGroups({ vpc, region: this.selectedRegion });
    },
  },
};
</script>
<template>
  <form name="eks-cluster-configuration-form">
    <h4>
      {{ s__('ClusterIntegration|Enter the details for your Amazon EKS Kubernetes cluster') }}
    </h4>
    <div class="mb-3">
      <gl-sprintf :message="$options.i18n.kubernetesIntegrationHelpText">
        <template #link="{ content }">
          <gl-link :href="kubernetesIntegrationHelpPath">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
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
    </div>
    <div class="form-group">
      <label class="label-bold" for="eks-role">{{ s__('ClusterIntegration|Service role') }}</label>
      <cluster-form-dropdown
        field-id="eks-role"
        field-name="eks-role"
        :value="selectedRole"
        :items="roles"
        :loading="isLoadingRoles"
        :loading-text="s__('ClusterIntegration|Loading IAM Roles')"
        :placeholder="s__('ClusterIntergation|Select service role')"
        :search-field-placeholder="s__('ClusterIntegration|Search IAM Roles')"
        :empty-text="s__('ClusterIntegration|No IAM Roles found')"
        :has-errors="Boolean(loadingRolesError)"
        :error-message="s__('ClusterIntegration|Could not load IAM roles')"
        @input="setRole({ role: $event })"
      />
      <p class="form-text text-muted">
        <gl-sprintf :message="$options.i18n.roleDropdownHelpText">
          <template #link="{ content }">
            <gl-link :href="$options.i18n.roleDropdownHelpPath" target="_blank">
              {{ content }}
              <gl-icon name="external-link" class="gl-vertical-align-middle" />
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </div>
    <gl-form-group
      :label="$options.i18n.regionInputLabel"
      :description="$options.i18n.regionHelpText"
    >
      <gl-form-input id="eks-region" :value="selectedRegion" type="text" readonly />
    </gl-form-group>
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
      <p class="form-text text-muted">
        <gl-sprintf :message="$options.i18n.keyPairDropdownHelpText">
          <template #link="{ content }">
            <gl-link :href="$options.i18n.keyPairDropdownHelpPath" target="_blank">
              {{ content }}
              <gl-icon name="external-link" class="gl-vertical-align-middle" />
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
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
      <p class="form-text text-muted">
        <gl-sprintf :message="$options.i18n.vpcDropdownHelpText">
          <template #link="{ content }">
            <gl-link :href="$options.i18n.vpcDropdownHelpPath" target="_blank">
              {{ content }}
              <gl-icon name="external-link" class="gl-vertical-align-middle" />
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
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
        :has-errors="displaySubnetError"
        :error-message="subnetValidationErrorText"
        @input="setSubnet({ subnet: $event })"
      />
      <p class="form-text text-muted">
        <gl-sprintf :message="$options.i18n.subnetDropdownHelpText">
          <template #link="{ content }">
            <gl-link :href="$options.i18n.subnetDropdownHelpPath" target="_blank">
              {{ content }}
              <gl-icon name="external-link" class="gl-vertical-align-middle" />
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
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
      <p class="form-text text-muted">
        <gl-sprintf :message="$options.i18n.securityGroupDropdownHelpText">
          <template #link="{ content }">
            <gl-link :href="$options.i18n.securityGroupDropdownHelpPath" target="_blank">
              {{ content }}
              <gl-icon name="external-link" class="gl-vertical-align-middle" />
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
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
      <p class="form-text text-muted">
        <gl-sprintf :message="$options.i18n.instanceTypesDropdownHelpText">
          <template #link="{ content }">
            <gl-link :href="$options.i18n.instanceTypesDropdownHelpPath" target="_blank">
              {{ content }}
              <gl-icon name="external-link" class="gl-vertical-align-middle" />
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
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
      <p class="form text text-muted">
        <gl-sprintf :message="$options.i18n.gitlabManagedClusterHelpText">
          <template #link="{ content }">
            <gl-link :href="gitlabManagedClusterHelpPath" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </div>
    <div class="form-group">
      <gl-form-checkbox
        :checked="namespacePerEnvironment"
        @input="setNamespacePerEnvironment({ namespacePerEnvironment: $event })"
        >{{ s__('ClusterIntegration|Namespace per environment') }}</gl-form-checkbox
      >
      <p class="form text text-muted">
        <gl-sprintf :message="$options.i18n.namespacePerEnvironmentHelpText">
          <template #link="{ content }">
            <gl-link :href="namespacePerEnvironmentHelpPath" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </div>
    <div class="form-group">
      <gl-button
        variant="success"
        category="primary"
        class="js-create-cluster"
        :disabled="createClusterButtonDisabled"
        :loading="isCreatingCluster"
        @click="createCluster()"
      >
        {{ createClusterButtonLabel }}
      </gl-button>
    </div>
  </form>
</template>
