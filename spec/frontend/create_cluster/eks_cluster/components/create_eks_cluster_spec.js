import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import CreateEksCluster from '~/create_cluster/eks_cluster/components/create_eks_cluster.vue';
import EksClusterConfigurationForm from '~/create_cluster/eks_cluster/components/eks_cluster_configuration_form.vue';
import ServiceCredentialsForm from '~/create_cluster/eks_cluster/components/service_credentials_form.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('CreateEksCluster', () => {
  let vm;
  let state;
  const gitlabManagedClusterHelpPath = 'gitlab-managed-cluster-help-path';
  const accountAndExternalIdsHelpPath = 'account-and-external-id-help-path';
  const createRoleArnHelpPath = 'role-arn-help-path';
  const kubernetesIntegrationHelpPath = 'kubernetes-integration';
  const externalLinkIcon = 'external-link';

  beforeEach(() => {
    state = { hasCredentials: false };
    const store = new Vuex.Store({
      state,
    });

    vm = shallowMount(CreateEksCluster, {
      propsData: {
        gitlabManagedClusterHelpPath,
        accountAndExternalIdsHelpPath,
        createRoleArnHelpPath,
        externalLinkIcon,
        kubernetesIntegrationHelpPath,
      },
      localVue,
      store,
    });
  });
  afterEach(() => vm.destroy());

  describe('when credentials are provided', () => {
    beforeEach(() => {
      state.hasCredentials = true;
    });

    it('displays eks cluster configuration form when credentials are valid', () => {
      expect(vm.find(EksClusterConfigurationForm).exists()).toBe(true);
    });

    describe('passes to the cluster configuration form', () => {
      it('help url for kubernetes integration documentation', () => {
        expect(vm.find(EksClusterConfigurationForm).props('gitlabManagedClusterHelpPath')).toBe(
          gitlabManagedClusterHelpPath,
        );
      });

      it('help url for gitlab managed cluster documentation', () => {
        expect(vm.find(EksClusterConfigurationForm).props('kubernetesIntegrationHelpPath')).toBe(
          kubernetesIntegrationHelpPath,
        );
      });
    });
  });

  describe('when credentials are invalid', () => {
    beforeEach(() => {
      state.hasCredentials = false;
    });

    it('displays service credentials form', () => {
      expect(vm.find(ServiceCredentialsForm).exists()).toBe(true);
    });

    describe('passes to the service credentials form', () => {
      it('help url for account and external ids', () => {
        expect(vm.find(ServiceCredentialsForm).props('accountAndExternalIdsHelpPath')).toBe(
          accountAndExternalIdsHelpPath,
        );
      });

      it('external link icon', () => {
        expect(vm.find(ServiceCredentialsForm).props('externalLinkIcon')).toBe(externalLinkIcon);
      });

      it('help url to create a role ARN', () => {
        expect(vm.find(ServiceCredentialsForm).props('createRoleArnHelpPath')).toBe(
          createRoleArnHelpPath,
        );
      });
    });
  });
});
