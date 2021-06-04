import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { DEFAULT_REGION } from '../constants';
import { setAWSConfig } from '../services/aws_services_facade';
import * as types from './mutation_types';

const getErrorMessage = (data) => {
  const errorKey = Object.keys(data)[0];

  return data[errorKey][0];
};

export const setClusterName = ({ commit }, payload) => {
  commit(types.SET_CLUSTER_NAME, payload);
};

export const setEnvironmentScope = ({ commit }, payload) => {
  commit(types.SET_ENVIRONMENT_SCOPE, payload);
};

export const setKubernetesVersion = ({ commit }, payload) => {
  commit(types.SET_KUBERNETES_VERSION, payload);
};

export const createRole = ({ dispatch, state: { createRolePath } }, payload) => {
  dispatch('requestCreateRole');

  const region = payload.selectedRegion || DEFAULT_REGION;

  return axios
    .post(createRolePath, {
      role_arn: payload.roleArn,
      role_external_id: payload.externalId,
      region,
    })
    .then(({ data }) => {
      const awsData = {
        ...convertObjectPropsToCamelCase(data),
        region,
      };

      dispatch('createRoleSuccess', awsData);
    })
    .catch((error) => {
      let message = error;
      if (error?.response?.data?.message) {
        message = error.response.data.message;
      }
      dispatch('createRoleError', { error: message });
    });
};

export const requestCreateRole = ({ commit }) => {
  commit(types.REQUEST_CREATE_ROLE);
};

export const createRoleSuccess = ({ dispatch, commit }, awsCredentials) => {
  dispatch('setRegion', { region: awsCredentials.region });
  setAWSConfig({ awsCredentials });
  commit(types.CREATE_ROLE_SUCCESS);
};

export const createRoleError = ({ commit }, payload) => {
  commit(types.CREATE_ROLE_ERROR, payload);
};

export const createCluster = ({ dispatch, state }) => {
  dispatch('requestCreateCluster');

  return axios
    .post(state.createClusterPath, {
      name: state.clusterName,
      environment_scope: state.environmentScope,
      managed: state.gitlabManagedCluster,
      namespace_per_environment: state.namespacePerEnvironment,
      provider_aws_attributes: {
        kubernetes_version: state.kubernetesVersion,
        region: state.selectedRegion,
        vpc_id: state.selectedVpc,
        subnet_ids: state.selectedSubnet,
        role_arn: state.selectedRole,
        key_name: state.selectedKeyPair,
        security_group_id: state.selectedSecurityGroup,
        instance_type: state.selectedInstanceType,
        num_nodes: state.nodeCount,
      },
    })
    .then(({ headers: { location } }) => dispatch('createClusterSuccess', location))
    .catch(({ response: { data } }) => {
      dispatch('createClusterError', data);
    });
};

export const requestCreateCluster = ({ commit }) => {
  commit(types.REQUEST_CREATE_CLUSTER);
};

export const createClusterSuccess = (_, location) => {
  window.location.assign(location);
};

export const createClusterError = ({ commit }, error) => {
  commit(types.CREATE_CLUSTER_ERROR, error);
  createFlash({
    message: getErrorMessage(error),
  });
};

export const setRegion = ({ commit }, payload) => {
  commit(types.SET_REGION, payload);
};

export const setKeyPair = ({ commit }, payload) => {
  commit(types.SET_KEY_PAIR, payload);
};

export const setVpc = ({ commit }, payload) => {
  commit(types.SET_VPC, payload);
};

export const setSubnet = ({ commit }, payload) => {
  commit(types.SET_SUBNET, payload);
};

export const setRole = ({ commit }, payload) => {
  commit(types.SET_ROLE, payload);
};

export const setSecurityGroup = ({ commit }, payload) => {
  commit(types.SET_SECURITY_GROUP, payload);
};

export const setGitlabManagedCluster = ({ commit }, payload) => {
  commit(types.SET_GITLAB_MANAGED_CLUSTER, payload);
};

export const setNamespacePerEnvironment = ({ commit }, payload) => {
  commit(types.SET_NAMESPACE_PER_ENVIRONMENT, payload);
};

export const setInstanceType = ({ commit }, payload) => {
  commit(types.SET_INSTANCE_TYPE, payload);
};

export const setNodeCount = ({ commit }, payload) => {
  commit(types.SET_NODE_COUNT, payload);
};
