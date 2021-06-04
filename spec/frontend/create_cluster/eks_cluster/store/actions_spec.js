import MockAdapter from 'axios-mock-adapter';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import testAction from 'helpers/vuex_action_helper';
import { DEFAULT_REGION } from '~/create_cluster/eks_cluster/constants';
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
  SET_NAMESPACE_PER_ENVIRONMENT,
  SET_INSTANCE_TYPE,
  SET_NODE_COUNT,
  REQUEST_CREATE_ROLE,
  CREATE_ROLE_SUCCESS,
  CREATE_ROLE_ERROR,
  REQUEST_CREATE_CLUSTER,
  CREATE_CLUSTER_ERROR,
} from '~/create_cluster/eks_cluster/store/mutation_types';
import createState from '~/create_cluster/eks_cluster/store/state';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

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
  let namespacePerEnvironment;
  let mock;
  let state;
  let newClusterUrl;

  beforeEach(() => {
    clusterName = 'my cluster';
    environmentScope = 'production';
    kubernetesVersion = '1.16';
    region = 'regions-1';
    vpc = 'vpc-1';
    subnet = 'subnet-1';
    role = 'role-1';
    keyPair = 'key-pair-1';
    securityGroup = 'default group';
    instanceType = 'small-1';
    nodeCount = '5';
    gitlabManagedCluster = true;
    namespacePerEnvironment = true;

    newClusterUrl = '/clusters/1';

    state = {
      ...createState(),
      createRolePath: '/clusters/roles/',
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
    action                          | mutation                         | payload                    | payloadDescription
    ${'setClusterName'}             | ${SET_CLUSTER_NAME}              | ${{ clusterName }}         | ${'cluster name'}
    ${'setEnvironmentScope'}        | ${SET_ENVIRONMENT_SCOPE}         | ${{ environmentScope }}    | ${'environment scope'}
    ${'setKubernetesVersion'}       | ${SET_KUBERNETES_VERSION}        | ${{ kubernetesVersion }}   | ${'kubernetes version'}
    ${'setRole'}                    | ${SET_ROLE}                      | ${{ role }}                | ${'role'}
    ${'setRegion'}                  | ${SET_REGION}                    | ${{ region }}              | ${'region'}
    ${'setKeyPair'}                 | ${SET_KEY_PAIR}                  | ${{ keyPair }}             | ${'key pair'}
    ${'setVpc'}                     | ${SET_VPC}                       | ${{ vpc }}                 | ${'vpc'}
    ${'setSubnet'}                  | ${SET_SUBNET}                    | ${{ subnet }}              | ${'subnet'}
    ${'setSecurityGroup'}           | ${SET_SECURITY_GROUP}            | ${{ securityGroup }}       | ${'securityGroup'}
    ${'setInstanceType'}            | ${SET_INSTANCE_TYPE}             | ${{ instanceType }}        | ${'instance type'}
    ${'setNodeCount'}               | ${SET_NODE_COUNT}                | ${{ nodeCount }}           | ${'node count'}
    ${'setGitlabManagedCluster'}    | ${SET_GITLAB_MANAGED_CLUSTER}    | ${gitlabManagedCluster}    | ${'gitlab managed cluster'}
    ${'setNamespacePerEnvironment'} | ${SET_NAMESPACE_PER_ENVIRONMENT} | ${namespacePerEnvironment} | ${'namespace per environment'}
  `(`$action commits $mutation with $payloadDescription payload`, (data) => {
    const { action, mutation, payload } = data;

    testAction(actions[action], payload, state, [{ type: mutation, payload }]);
  });

  describe('createRole', () => {
    const payload = {
      roleArn: 'role_arn',
      externalId: 'externalId',
    };
    const response = {
      accessKeyId: 'access-key-id',
      secretAccessKey: 'secret-key-id',
    };

    describe('when request succeeds with default region', () => {
      beforeEach(() => {
        mock
          .onPost(state.createRolePath, {
            role_arn: payload.roleArn,
            role_external_id: payload.externalId,
            region: DEFAULT_REGION,
          })
          .reply(201, response);
      });

      it('dispatches createRoleSuccess action', () =>
        testAction(
          actions.createRole,
          payload,
          state,
          [],
          [
            { type: 'requestCreateRole' },
            {
              type: 'createRoleSuccess',
              payload: {
                region: DEFAULT_REGION,
                ...response,
              },
            },
          ],
        ));
    });

    describe('when request succeeds with custom region', () => {
      const customRegion = 'custom-region';

      beforeEach(() => {
        mock
          .onPost(state.createRolePath, {
            role_arn: payload.roleArn,
            role_external_id: payload.externalId,
            region: customRegion,
          })
          .reply(201, response);
      });

      it('dispatches createRoleSuccess action', () =>
        testAction(
          actions.createRole,
          {
            selectedRegion: customRegion,
            ...payload,
          },
          state,
          [],
          [
            { type: 'requestCreateRole' },
            {
              type: 'createRoleSuccess',
              payload: {
                region: customRegion,
                ...response,
              },
            },
          ],
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
            region: DEFAULT_REGION,
          })
          .reply(400, null);
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

    describe('when request fails with a message', () => {
      beforeEach(() => {
        const errResp = { message: 'Something failed' };

        mock
          .onPost(state.createRolePath, {
            role_arn: payload.roleArn,
            role_external_id: payload.externalId,
            region: DEFAULT_REGION,
          })
          .reply(4, errResp);
      });

      it('dispatches createRoleError action', () =>
        testAction(
          actions.createRole,
          payload,
          state,
          [],
          [
            { type: 'requestCreateRole' },
            { type: 'createRoleError', payload: { error: 'Something failed' } },
          ],
        ));
    });
  });

  describe('requestCreateRole', () => {
    it('commits requestCreaterole mutation', () => {
      testAction(actions.requestCreateRole, null, state, [{ type: REQUEST_CREATE_ROLE }]);
    });
  });

  describe('createRoleSuccess', () => {
    it('sets region and commits createRoleSuccess mutation', () => {
      testAction(
        actions.createRoleSuccess,
        { region },
        state,
        [{ type: CREATE_ROLE_SUCCESS }],
        [{ type: 'setRegion', payload: { region } }],
      );
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
        namespace_per_environment: namespacePerEnvironment,
        provider_aws_attributes: {
          kubernetes_version: kubernetesVersion,
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
        namespacePerEnvironment,
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
    useMockLocationHelper();

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

    it('commits createClusterError mutation and displays flash message', () =>
      testAction(actions.createClusterError, payload, state, [
        { type: CREATE_CLUSTER_ERROR, payload },
      ]).then(() => {
        expect(createFlash).toHaveBeenCalledWith({
          message: payload.name[0],
        });
      }));
  });
});
