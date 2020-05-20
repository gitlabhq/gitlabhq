import Vue from 'vue';
import component from '~/jobs/components/environments_block.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

const TEST_CLUSTER_NAME = 'test_cluster';
const TEST_CLUSTER_PATH = 'path/to/test_cluster';
const TEST_KUBERNETES_NAMESPACE = 'this-is-a-kubernetes-namespace';

describe('Environments block', () => {
  const Component = Vue.extend(component);
  let vm;
  const status = {
    group: 'success',
    icon: 'status_success',
    label: 'passed',
    text: 'passed',
    tooltip: 'passed',
  };

  const environment = {
    environment_path: '/environment',
    name: 'environment',
  };

  const lastDeployment = { iid: 'deployment', deployable: { build_path: 'bar' } };

  const createEnvironmentWithLastDeployment = () => ({
    ...environment,
    last_deployment: { ...lastDeployment },
  });

  const createDeploymentWithCluster = () => ({ name: TEST_CLUSTER_NAME, path: TEST_CLUSTER_PATH });

  const createDeploymentWithClusterAndKubernetesNamespace = () => ({
    name: TEST_CLUSTER_NAME,
    path: TEST_CLUSTER_PATH,
    kubernetes_namespace: TEST_KUBERNETES_NAMESPACE,
  });

  const createComponent = (deploymentStatus = {}, deploymentCluster = {}) => {
    vm = mountComponent(Component, {
      deploymentStatus,
      deploymentCluster,
      iconStatus: status,
    });
  };

  const findText = () => vm.$el.textContent.trim();
  const findJobDeploymentLink = () => vm.$el.querySelector('.js-job-deployment-link');
  const findEnvironmentLink = () => vm.$el.querySelector('.js-environment-link');
  const findClusterLink = () => vm.$el.querySelector('.js-job-cluster-link');

  afterEach(() => {
    vm.$destroy();
  });

  describe('with last deployment', () => {
    it('renders info for most recent deployment', () => {
      createComponent({
        status: 'last',
        environment,
      });

      expect(findText()).toEqual('This job is deployed to environment.');
    });

    describe('when there is a cluster', () => {
      it('renders info with cluster', () => {
        createComponent(
          {
            status: 'last',
            environment: createEnvironmentWithLastDeployment(),
          },
          createDeploymentWithCluster(),
        );

        expect(findText()).toEqual(
          `This job is deployed to environment using cluster ${TEST_CLUSTER_NAME}.`,
        );
      });

      describe('when there is a kubernetes namespace', () => {
        it('renders info with cluster', () => {
          createComponent(
            {
              status: 'last',
              environment: createEnvironmentWithLastDeployment(),
            },
            createDeploymentWithClusterAndKubernetesNamespace(),
          );

          expect(findText()).toEqual(
            `This job is deployed to environment using cluster ${TEST_CLUSTER_NAME} and namespace ${TEST_KUBERNETES_NAMESPACE}.`,
          );
        });
      });
    });
  });

  describe('with out of date deployment', () => {
    describe('with last deployment', () => {
      it('renders info for out date and most recent', () => {
        createComponent({
          status: 'out_of_date',
          environment: createEnvironmentWithLastDeployment(),
        });

        expect(findText()).toEqual(
          'This job is an out-of-date deployment to environment. View the most recent deployment.',
        );

        expect(findJobDeploymentLink().getAttribute('href')).toEqual('bar');
      });

      describe('when there is a cluster', () => {
        it('renders info with cluster', () => {
          createComponent(
            {
              status: 'out_of_date',
              environment: createEnvironmentWithLastDeployment(),
            },
            createDeploymentWithCluster(),
          );

          expect(findText()).toEqual(
            `This job is an out-of-date deployment to environment using cluster ${TEST_CLUSTER_NAME}. View the most recent deployment.`,
          );
        });

        describe('when there is a kubernetes namespace', () => {
          it('renders info with cluster', () => {
            createComponent(
              {
                status: 'out_of_date',
                environment: createEnvironmentWithLastDeployment(),
              },
              createDeploymentWithClusterAndKubernetesNamespace(),
            );

            expect(findText()).toEqual(
              `This job is an out-of-date deployment to environment using cluster ${TEST_CLUSTER_NAME} and namespace ${TEST_KUBERNETES_NAMESPACE}. View the most recent deployment.`,
            );
          });
        });
      });
    });

    describe('without last deployment', () => {
      it('renders info about out of date deployment', () => {
        createComponent({
          status: 'out_of_date',
          environment,
        });

        expect(findText()).toEqual('This job is an out-of-date deployment to environment.');
      });
    });
  });

  describe('with failed deployment', () => {
    it('renders info about failed deployment', () => {
      createComponent({
        status: 'failed',
        environment,
      });

      expect(findText()).toEqual('The deployment of this job to environment did not succeed.');
    });
  });

  describe('creating deployment', () => {
    describe('with last deployment', () => {
      it('renders info about creating deployment and overriding latest deployment', () => {
        createComponent({
          status: 'creating',
          environment: createEnvironmentWithLastDeployment(),
        });

        expect(findText()).toEqual(
          'This job is creating a deployment to environment. This will overwrite the latest deployment.',
        );

        expect(findJobDeploymentLink().getAttribute('href')).toEqual('bar');
        expect(findEnvironmentLink().getAttribute('href')).toEqual(environment.environment_path);
        expect(findClusterLink()).toBeNull();
      });
    });

    describe('without last deployment', () => {
      it('renders info about deployment being created', () => {
        createComponent({
          status: 'creating',
          environment,
        });

        expect(findText()).toEqual('This job is creating a deployment to environment.');
      });

      describe('when there is a cluster', () => {
        it('inclues information about the cluster', () => {
          createComponent(
            {
              status: 'creating',
              environment,
            },
            createDeploymentWithCluster(),
          );

          expect(findText()).toEqual(
            `This job is creating a deployment to environment using cluster ${TEST_CLUSTER_NAME}.`,
          );
        });
      });
    });

    describe('without environment', () => {
      it('does not render environment link', () => {
        createComponent({
          status: 'creating',
          environment: null,
        });

        expect(findEnvironmentLink()).toBeNull();
      });
    });
  });

  describe('with a cluster', () => {
    it('renders the cluster link', () => {
      createComponent(
        {
          status: 'last',
          environment: createEnvironmentWithLastDeployment(),
        },
        createDeploymentWithCluster(),
      );

      expect(findText()).toEqual(
        `This job is deployed to environment using cluster ${TEST_CLUSTER_NAME}.`,
      );

      expect(findClusterLink().getAttribute('href')).toEqual(TEST_CLUSTER_PATH);
    });

    describe('when the cluster is missing the path', () => {
      it('renders the name without a link', () => {
        createComponent(
          {
            status: 'last',
            environment: createEnvironmentWithLastDeployment(),
          },
          { name: 'the-cluster' },
        );

        expect(findText()).toContain('using cluster the-cluster.');

        expect(findClusterLink()).toBeNull();
      });
    });
  });
});
