import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';

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

  return axios
    .post(createRolePath, {
      role_arn: payload.roleArn,
      role_external_id: payload.externalId,
    })
    .then(() => dispatch('createRoleSuccess'))
    .catch(error => dispatch('createRoleError', { error }));
};

export const requestCreateRole = ({ commit }) => {
  commit(types.REQUEST_CREATE_ROLE);
};

export const createRoleSuccess = ({ commit }) => {
  commit(types.CREATE_ROLE_SUCCESS);
};

export const createRoleError = ({ commit }, payload) => {
  commit(types.CREATE_ROLE_ERROR, payload);
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
