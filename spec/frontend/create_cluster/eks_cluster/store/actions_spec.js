import testAction from 'helpers/vuex_action_helper';

import createState from '~/create_cluster/eks_cluster/store/state';
import * as actions from '~/create_cluster/eks_cluster/store/actions';
import {
  SET_CLUSTER_NAME,
  SET_ENVIRONMENT_SCOPE,
  SET_KUBERNETES_VERSION,
  SET_REGION,
  SET_VPC,
  SET_KEY_PAIR,
  SET_SUBNET,
  SET_ROLE,
  SET_SECURITY_GROUP,
  SET_GITLAB_MANAGED_CLUSTER,
} from '~/create_cluster/eks_cluster/store/mutation_types';

describe('EKS Cluster Store Actions', () => {
  let clusterName;
  let environmentScope;
  let kubernetesVersion;
  let region;
  let vpc;
  let subnet;
  let role;
  let keyPair;
  let securityGroup;
  let gitlabManagedCluster;

  beforeEach(() => {
    clusterName = 'my cluster';
    environmentScope = 'production';
    kubernetesVersion = '11.1';
    region = { name: 'regions-1' };
    vpc = { name: 'vpc-1' };
    subnet = { name: 'subnet-1' };
    role = { name: 'role-1' };
    keyPair = { name: 'key-pair-1' };
    securityGroup = { name: 'default group' };
    gitlabManagedCluster = true;
  });

  it.each`
    action                       | mutation                      | payload                  | payloadDescription
    ${'setClusterName'}          | ${SET_CLUSTER_NAME}           | ${{ clusterName }}       | ${'cluster name'}
    ${'setEnvironmentScope'}     | ${SET_ENVIRONMENT_SCOPE}      | ${{ environmentScope }}  | ${'environment scope'}
    ${'setKubernetesVersion'}    | ${SET_KUBERNETES_VERSION}     | ${{ kubernetesVersion }} | ${'kubernetes version'}
    ${'setRole'}                 | ${SET_ROLE}                   | ${{ role }}              | ${'role'}
    ${'setRegion'}               | ${SET_REGION}                 | ${{ region }}            | ${'region'}
    ${'setKeyPair'}              | ${SET_KEY_PAIR}               | ${{ keyPair }}           | ${'key pair'}
    ${'setVpc'}                  | ${SET_VPC}                    | ${{ vpc }}               | ${'vpc'}
    ${'setSubnet'}               | ${SET_SUBNET}                 | ${{ subnet }}            | ${'subnet'}
    ${'setSecurityGroup'}        | ${SET_SECURITY_GROUP}         | ${{ securityGroup }}     | ${'securityGroup'}
    ${'setGitlabManagedCluster'} | ${SET_GITLAB_MANAGED_CLUSTER} | ${gitlabManagedCluster}  | ${'gitlab managed cluster'}
  `(`$action commits $mutation with $payloadDescription payload`, data => {
    const { action, mutation, payload } = data;

    testAction(actions[action], payload, createState(), [{ type: mutation, payload }]);
  });
});
