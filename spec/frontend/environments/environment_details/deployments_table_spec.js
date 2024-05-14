import resolvedEnvironmentDetails from 'test_fixtures/graphql/environments/graphql/queries/environment_details.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Commit from '~/vue_shared/components/commit.vue';
import DeploymentStatusLink from '~/environments/components/deployment_status_link.vue';
import DeploymentJob from '~/environments/environment_details/components/deployment_job.vue';
import DeploymentTriggerer from '~/environments/environment_details/components/deployment_triggerer.vue';
import DeploymentActions from '~/environments/environment_details/components/deployment_actions.vue';
import DeploymentsTable from '~/environments/environment_details/deployments_table.vue';
import { convertToDeploymentTableRow } from '~/environments/helpers/deployment_data_transformation_helper';

const { environment } = resolvedEnvironmentDetails.data.project;
const deployments = environment.deployments.nodes.map((d) =>
  convertToDeploymentTableRow(d, environment),
);

describe('~/environments/environment_details/index.vue', () => {
  let wrapper;

  const createWrapper = (propsData = {}) => {
    wrapper = mountExtended(DeploymentsTable, {
      propsData: {
        deployments,
        ...propsData,
      },
    });
  };

  describe('deployment row', () => {
    const [, , deployment] = deployments;

    let row;

    beforeEach(() => {
      createWrapper();

      row = wrapper.find('tr:nth-child(3)');
    });

    it.each`
      cell                    | component                                   | props
      ${'status'}             | ${DeploymentStatusLink}                     | ${{ deploymentJob: deployment.job, status: deployment.status }}
      ${'triggerer'}          | ${DeploymentTriggerer}                      | ${{ triggerer: deployment.triggerer }}
      ${'commit'}             | ${Commit}                                   | ${deployment.commit}
      ${'job'}                | ${DeploymentJob}                            | ${{ job: deployment.job }}
      ${'created date'}       | ${'[data-testid="deployment-created-at"]'}  | ${{ time: deployment.created }}
      ${'deployed date'}      | ${'[data-testid="deployment-deployed-at"]'} | ${{ time: deployment.deployed }}
      ${'deployment actions'} | ${DeploymentActions}                        | ${{ actions: deployment.actions, rollback: deployment.rollback, approvalEnvironment: deployment.deploymentApproval }}
    `('should show the correct component for $cell', ({ component, props }) => {
      expect(row.findComponent(component).props()).toMatchObject(props);
    });

    it('hides the deployed at timestamp for not-finished deployments', () => {
      row = wrapper.find('tr');

      expect(row.find('[data-testid="deployment-deployed-at"]').exists()).toBe(false);
    });
  });
});
