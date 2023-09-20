import { mount } from '@vue/test-utils';
import EnvironmentsBlock from '~/ci/job_details/components/environments_block.vue';

const TEST_CLUSTER_NAME = 'test_cluster';
const TEST_CLUSTER_PATH = 'path/to/test_cluster';
const TEST_KUBERNETES_NAMESPACE = 'this-is-a-kubernetes-namespace';

describe('Environments block', () => {
  let wrapper;

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
    wrapper = mount(EnvironmentsBlock, {
      propsData: {
        deploymentStatus,
        deploymentCluster,
        iconStatus: status,
      },
    });
  };

  const findText = () => wrapper.findComponent(EnvironmentsBlock).text();
  const findJobDeploymentLink = () => wrapper.find('[data-testid="job-deployment-link"]');
  const findEnvironmentLink = () => wrapper.find('[data-testid="job-environment-link"]');
  const findClusterLink = () => wrapper.find('[data-testid="job-cluster-link"]');

  describe('with last deployment', () => {
    it('renders info for most recent deployment', () => {
      createComponent({
        status: 'last',
        environment,
      });

      expect(findText()).toBe('This job is deployed to environment.');
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

        expect(findText()).toBe(
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

          expect(findText()).toBe(
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

        expect(findText()).toBe(
          'This job is an out-of-date deployment to environment. View the most recent deployment.',
        );

        expect(findJobDeploymentLink().attributes('href')).toBe('bar');
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

          expect(findText()).toBe(
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

            expect(findText()).toBe(
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

        expect(findText()).toBe('This job is an out-of-date deployment to environment.');
      });
    });
  });

  describe('with failed deployment', () => {
    it('renders info about failed deployment', () => {
      createComponent({
        status: 'failed',
        environment,
      });

      expect(findText()).toBe('The deployment of this job to environment did not succeed.');
    });
  });

  describe('creating deployment', () => {
    describe('with last deployment', () => {
      it('renders info about creating deployment and overriding latest deployment', () => {
        createComponent({
          status: 'creating',
          environment: createEnvironmentWithLastDeployment(),
        });

        expect(findText()).toBe(
          'This job is creating a deployment to environment. This will overwrite the latest deployment.',
        );

        expect(findEnvironmentLink().attributes('href')).toBe(environment.environment_path);

        expect(findJobDeploymentLink().attributes('href')).toBe('bar');

        expect(findClusterLink().exists()).toBe(false);
      });
    });

    describe('without last deployment', () => {
      it('renders info about deployment being created', () => {
        createComponent({
          status: 'creating',
          environment,
        });

        expect(findText()).toBe('This job is creating a deployment to environment.');
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

          expect(findText()).toBe(
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

        expect(findEnvironmentLink().exists()).toBe(false);
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

      expect(findText()).toBe(
        `This job is deployed to environment using cluster ${TEST_CLUSTER_NAME}.`,
      );

      expect(findClusterLink().attributes('href')).toBe(TEST_CLUSTER_PATH);
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

        expect(findClusterLink().exists()).toBe(false);
      });
    });
  });
});
