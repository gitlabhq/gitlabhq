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
  SET_INSTANCE_TYPE,
  SET_NODE_COUNT,
  REQUEST_CREATE_ROLE,
  CREATE_ROLE_SUCCESS,
  CREATE_ROLE_ERROR,
  REQUEST_CREATE_CLUSTER,
  CREATE_CLUSTER_ERROR,
  SIGN_OUT,
} from '~/create_cluster/eks_cluster/store/mutation_types';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import createFlash from '~/flash';

jest.mock('~/flash');

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
  let instanceType;
  let nodeCount;
  let gitlabManagedCluster;
  let mock;
  let state;
  let newClusterUrl;

  beforeEach(() => {
    clusterName = 'my cluster';
    environmentScope = 'production';
    kubernetesVersion = '11.1';
    region = 'regions-1';
    vpc = 'vpc-1';
    subnet = 'subnet-1';
    role = 'role-1';
    keyPair = 'key-pair-1';
    securityGroup = 'default group';
    instanceType = 'small-1';
    nodeCount = '5';
    gitlabManagedCluster = true;

    newClusterUrl = '/clusters/1';

    state = {
      ...createState(),
      createRolePath: '/clusters/roles/',
      signOutPath: '/aws/signout',
      createClusterPath: '/clusters/',
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
    ${'setInstanceType'}         | ${SET_INSTANCE_TYPE}          | ${{ instanceType }}      | ${'instance type'}
    ${'setNodeCount'}            | ${SET_NODE_COUNT}             | ${{ nodeCount }}         | ${'node count'}
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

  describe('createCluster', () => {
    let requestPayload;

    beforeEach(() => {
      requestPayload = {
        name: clusterName,
        environment_scope: environmentScope,
        managed: gitlabManagedCluster,
        provider_aws_attributes: {
          region,
          vpc_id: vpc,
          subnet_ids: subnet,
          role_arn: role,
          key_name: keyPair,
          security_group_id: securityGroup,
          instance_type: instanceType,
          num_nodes: nodeCount,
        },
      };
      state = Object.assign(createState(), {
        clusterName,
        environmentScope,
        kubernetesVersion,
        selectedRegion: region,
        selectedVpc: vpc,
        selectedSubnet: subnet,
        selectedRole: role,
        selectedKeyPair: keyPair,
        selectedSecurityGroup: securityGroup,
        selectedInstanceType: instanceType,
        nodeCount,
        gitlabManagedCluster,
      });
    });

    describe('when request succeeds', () => {
      beforeEach(() => {
        mock.onPost(state.createClusterPath, requestPayload).reply(201, null, {
          location: '/clusters/1',
        });
      });

      it('dispatches createClusterSuccess action', () =>
        testAction(
          actions.createCluster,
          null,
          state,
          [],
          [
            { type: 'requestCreateCluster' },
            { type: 'createClusterSuccess', payload: newClusterUrl },
          ],
        ));
    });

    describe('when request fails', () => {
      let response;

      beforeEach(() => {
        response = 'Request failed with status code 400';
        mock.onPost(state.createClusterPath, requestPayload).reply(400, response);
      });

      it('dispatches createRoleError action', () =>
        testAction(
          actions.createCluster,
          null,
          state,
          [],
          [{ type: 'requestCreateCluster' }, { type: 'createClusterError', payload: response }],
        ));
    });
  });

  describe('requestCreateCluster', () => {
    it('commits requestCreateCluster mutation', () => {
      testAction(actions.requestCreateCluster, null, state, [{ type: REQUEST_CREATE_CLUSTER }]);
    });
  });

  describe('createClusterSuccess', () => {
    beforeEach(() => {
      jest.spyOn(window.location, 'assign').mockImplementation(() => {});
    });
    afterEach(() => {
      window.location.assign.mockRestore();
    });

    it('redirects to the new cluster URL', () => {
      actions.createClusterSuccess(null, newClusterUrl);

      expect(window.location.assign).toHaveBeenCalledWith(newClusterUrl);
    });
  });

  describe('createClusterError', () => {
    let payload;

    beforeEach(() => {
      payload = { name: ['Create cluster failed'] };
    });

    it('commits createClusterError mutation', () => {
      testAction(actions.createClusterError, payload, state, [
        { type: CREATE_CLUSTER_ERROR, payload },
      ]);
    });

    it('creates a flash that displays the create cluster error', () => {
      expect(createFlash).toHaveBeenCalledWith(payload.name[0]);
    });
  });

  describe('signOut', () => {
    beforeEach(() => {
      mock.onDelete(state.signOutPath).reply(200, null);
    });

    it('commits signOut mutation', () => {
      testAction(actions.signOut, null, state, [{ type: SIGN_OUT }]);
    });
  });
});
