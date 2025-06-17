import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PagesDeployment from '~/gitlab_pages/components/deployment.vue';
import deletePagesDeploymentMutation from '~/gitlab_pages/queries/delete_pages_deployment.mutation.graphql';
import restorePagesDeploymentMutation from '~/gitlab_pages/queries/restore_pages_deployment.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import UserDate from '~/vue_shared/components/user_date.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  primaryDeployment,
  environmentDeployment,
  deleteDeploymentResult,
  restoreDeploymentResult,
} from '../mock_data';

Vue.use(VueApollo);

describe('PagesDeployment', () => {
  let wrapper;

  const deletePagesDeploymentMutationHandler = jest.fn().mockResolvedValue(deleteDeploymentResult);
  const restorePagesDeploymentMutationHandler = jest
    .fn()
    .mockResolvedValue(restoreDeploymentResult);

  const createComponent = (props = {}) => {
    wrapper = mountExtended(PagesDeployment, {
      apolloProvider: createMockApollo([
        [deletePagesDeploymentMutation, deletePagesDeploymentMutationHandler],
        [restorePagesDeploymentMutation, restorePagesDeploymentMutationHandler],
      ]),
      propsData: {
        deployment: primaryDeployment,
        ...props,
      },
      provide: {
        projectFullPath: 'my-group/my-project',
      },
    });
  };

  const deleteDeployment = () => {
    wrapper.findByTestId('deployment-delete').trigger('click');
  };
  const restoreDeployment = () => {
    wrapper.findByTestId('deployment-restore').trigger('click');
  };

  const findErrorBadge = () => wrapper.findByTestId('error-badge');

  describe.each`
    description                 | deployment
    ${'Primary deployment'}     | ${primaryDeployment}
    ${'Environment deployment'} | ${environmentDeployment}
  `('$description', ({ deployment }) => {
    beforeEach(() => {
      createComponent({ deployment });
    });

    describe('display expected data', () => {
      it('renders deployment details', () => {
        expect(wrapper.findByTestId('deployment-url').text()).toBe(deployment.url);
        expect(
          wrapper.findByTestId('deployment-created-at').findComponent(TimeAgo).props('time'),
        ).toBe(deployment.createdAt);
        expect(wrapper.findByTestId('deployment-ci-build-id').text()).toContain(
          deployment.ciBuildId.toString(),
        );
        expect(wrapper.findByTestId('deployment-root-directory').text()).toContain(
          `/${deployment.rootDirectory}`,
        );
        expect(wrapper.findByTestId('deployment-file-count').text()).toContain(
          deployment.fileCount.toString(),
        );
        expect(wrapper.findByTestId('deployment-size').text()).toContain('1.0 KiB');
        expect(
          wrapper.findByTestId('deployment-updated-at').findComponent(TimeAgo).props('time'),
        ).toBe(deployment.updatedAt);

        if (deployment.expiresAt) {
          expect(
            wrapper.findByTestId('deployment-expires-at').findComponent(UserDate).props('date'),
          ).toBe(deployment.expiresAt);
        } else {
          expect(wrapper.findByTestId('deployment-expires-at').text()).toBe('Never expires');
        }
      });
    });

    describe('deployment is active', () => {
      it('shows the deployment as active', () => {
        expect(wrapper.findByTestId('deployment-state').text()).toBe('Active');
      });

      it('renders the deployment URL as a hyperlink', () => {
        expect(wrapper.findByTestId('deployment-url').find('a').attributes('href')).toBe(
          deployment.url,
        );
      });

      it('deletes deployment when delete button is clicked', async () => {
        await deleteDeployment();

        expect(deletePagesDeploymentMutationHandler).toHaveBeenCalledWith({
          deploymentId: deployment.id,
        });
      });
    });

    describe('deployment is inactive', () => {
      beforeEach(() => {
        createComponent({ deployment: { ...deployment, active: false } });
      });

      it('shows the deployment as stopped', () => {
        expect(wrapper.findByTestId('deployment-state').text()).toBe('Stopped');
      });

      it('does not render the deployment URL as a hyperlink', () => {
        expect(wrapper.findByTestId('deployment-url').find('a').exists()).toBe(false);
      });

      it('renders restore button', () => {
        expect(wrapper.findByTestId('deployment-restore').exists()).toBe(true);
      });

      it('does not render delete button', () => {
        expect(wrapper.findByTestId('deployment-delete').exists()).toBe(false);
      });

      it('restores deployment when restore button is clicked', async () => {
        await restoreDeployment();

        expect(restorePagesDeploymentMutationHandler).toHaveBeenCalledWith({
          deploymentId: deployment.id,
        });
      });
    });
  });

  describe.each`
    method         | deploymentActiveState | mutationHandler                          | action               | expectedErrorMessage
    ${'deleting'}  | ${true}               | ${deletePagesDeploymentMutationHandler}  | ${deleteDeployment}  | ${'An error occurred while deleting the deployment. Check your connection and try again.'}
    ${'restoring'} | ${false}              | ${restorePagesDeploymentMutationHandler} | ${restoreDeployment} | ${'Restoring the deployment failed. The deployment might be permanently deleted.'}
  `(
    '$method produces an error',
    ({ deploymentActiveState, mutationHandler, action, expectedErrorMessage }) => {
      beforeEach(async () => {
        mutationHandler.mockResolvedValue({
          deletePagesDeployment: {
            errors: ['Something went wrong'],
            pagesDeployment: null,
          },
        });
        createComponent({
          deployment: { ...primaryDeployment, active: deploymentActiveState },
        });

        await action();

        await waitForPromises();
      });

      it('emits an error', () => {
        expect(wrapper.emitted('error')).toEqual([
          [
            {
              id: primaryDeployment.id,
              message: expectedErrorMessage,
            },
          ],
        ]);
      });

      it('shows error badge', () => {
        expect(findErrorBadge().exists()).toBe(true);
      });
    },
  );
});
