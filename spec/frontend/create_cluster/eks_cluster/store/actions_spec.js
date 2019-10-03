import testAction from 'helpers/vuex_action_helper';

import createState from '~/create_cluster/eks_cluster/store/state';
import * as actions from '~/create_cluster/eks_cluster/store/actions';
import { SET_REGION, SET_VPC, SET_SUBNET } from '~/create_cluster/eks_cluster/store/mutation_types';

describe('EKS Cluster Store Actions', () => {
  let region;
  let vpc;
  let subnet;

  beforeEach(() => {
    region = { name: 'regions-1' };
    vpc = { name: 'vpc-1' };
    subnet = { name: 'subnet-1' };
  });

  it.each`
    action         | mutation      | payload       | payloadDescription
    ${'setRegion'} | ${SET_REGION} | ${{ region }} | ${'region'}
    ${'setVpc'}    | ${SET_VPC}    | ${{ vpc }}    | ${'vpc'}
    ${'setSubnet'} | ${SET_SUBNET} | ${{ subnet }} | ${'subnet'}
  `(`$action commits $mutation with $payloadDescription payload`, data => {
    const { action, mutation, payload } = data;

    testAction(actions[action], payload, createState(), [{ type: mutation, payload }]);
  });
});
