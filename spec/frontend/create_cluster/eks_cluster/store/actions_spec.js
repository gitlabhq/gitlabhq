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
  REQUEST_CREATE_ROLE,
  CREATE_ROLE_SUCCESS,
  CREATE_ROLE_ERROR,
} from '~/create_cluster/eks_cluster/store/mutation_types';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';

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
  let mock;
  let state;

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

    state = {
      ...createState(),
      createRolePath: '/clusters/roles/',
    };
  });

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
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

    testAction(actions[action], payload, state, [{ type: mutation, payload }]);
  });

  describe('createRole', () => {
    const payload = {
      roleArn: 'role_arn',
      externalId: 'externalId',
    };

    describe('when request succeeds', () => {
      beforeEach(() => {
        mock
          .onPost(state.createRolePath, {
            role_arn: payload.roleArn,
            role_external_id: payload.externalId,
          })
          .reply(201);
      });

      it('dispatches createRoleSuccess action', () =>
        testAction(
          actions.createRole,
          payload,
          state,
          [],
          [{ type: 'requestCreateRole' }, { type: 'createRoleSuccess' }],
        ));
    });

    describe('when request fails', () => {
      let error;

      beforeEach(() => {
        error = new Error('Request failed with status code 400');
        mock
          .onPost(state.createRolePath, {
            role_arn: payload.roleArn,
            role_external_id: payload.externalId,
          })
          .reply(400, error);
      });

      it('dispatches createRoleError action', () =>
        testAction(
          actions.createRole,
          payload,
          state,
          [],
          [{ type: 'requestCreateRole' }, { type: 'createRoleError', payload: { error } }],
        ));
    });
  });

  describe('requestCreateRole', () => {
    it('commits requestCreaterole mutation', () => {
      testAction(actions.requestCreateRole, null, state, [{ type: REQUEST_CREATE_ROLE }]);
    });
  });

  describe('createRoleSuccess', () => {
    it('commits createRoleSuccess mutation', () => {
      testAction(actions.createRoleSuccess, null, state, [{ type: CREATE_ROLE_SUCCESS }]);
    });
  });

  describe('createRoleError', () => {
    it('commits createRoleError mutation', () => {
      const payload = {
        error: new Error(),
      };

      testAction(actions.createRoleError, payload, state, [{ type: CREATE_ROLE_ERROR, payload }]);
    });
  });
});
