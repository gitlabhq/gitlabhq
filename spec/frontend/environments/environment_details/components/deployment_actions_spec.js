import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton } from '@gitlab/ui';
import DeploymentActions from '~/environments/environment_details/components/deployment_actions.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { translations } from '~/environments/environment_details/constants';
import ActionsComponent from '~/environments/components/environment_actions.vue';

describe('~/environments/environment_details/components/deployment_actions.vue', () => {
  Vue.use(VueApollo);
  let wrapper;

  const actionsData = [
    {
      playable: true,
      playPath: 'http://www.example.com/play',
      name: 'deploy-staging',
      scheduledAt: '2023-01-18T08:50:08.390Z',
    },
  ];

  const rollbackData = {
    id: '123',
    name: 'enironment-name',
    lastDeployment: {
      commit: {
        shortSha: 'abcd1234',
      },
      isLast: true,
    },
    retryUrl: 'deployment/retry',
  };

  const mockSetEnvironmentToRollback = jest.fn();
  const mockResolvers = {
    Mutation: {
      setEnvironmentToRollback: mockSetEnvironmentToRollback,
    },
  };
  const createWrapper = ({ actions, rollback, approvalEnvironment }) => {
    const mockApollo = createMockApollo([], mockResolvers);
    return mountExtended(DeploymentActions, {
      apolloProvider: mockApollo,
      provide: {
        projectPath: 'fullProjectPath',
      },
      propsData: {
        actions,
        rollback,
        approvalEnvironment,
      },
    });
  };

  const findRollbackButton = () => wrapper.findComponent(GlButton);

  describe('deployment actions', () => {
    describe('when there is no actions provided', () => {
      beforeEach(() => {
        wrapper = createWrapper({ actions: [] });
      });

      it('should not render actions component', () => {
        const actionsComponent = wrapper.findComponent(ActionsComponent);
        expect(actionsComponent.exists()).toBe(false);
      });
    });

    describe('when there are actions provided', () => {
      beforeEach(() => {
        wrapper = createWrapper({ actions: actionsData });
      });

      it('should render actions component', () => {
        const actionsComponent = wrapper.findComponent(ActionsComponent);
        expect(actionsComponent.exists()).toBe(true);
        expect(actionsComponent.props().actions).toBe(actionsData);
      });
    });
  });

  describe('rollback action', () => {
    describe('when there is no rollback data available', () => {
      it('should not show a rollback button', () => {
        wrapper = createWrapper({ actions: [] });
        const button = findRollbackButton();
        expect(button.exists()).toBe(false);
      });
    });

    describe.each([
      { isLast: true, buttonTitle: translations.redeployButtonTitle, icon: 'repeat' },
      { isLast: false, buttonTitle: translations.rollbackButtonTitle, icon: 'redo' },
    ])(
      `when there is a rollback data available and the deployment isLast=$isLast`,
      ({ isLast, buttonTitle, icon }) => {
        let rollback;
        beforeEach(() => {
          const lastDeployment = { ...rollbackData.lastDeployment, isLast };
          rollback = { ...rollbackData };
          rollback.lastDeployment = lastDeployment;
          wrapper = createWrapper({ actions: [], rollback });
        });

        it('should show the rollback button', () => {
          const button = findRollbackButton();
          expect(button.exists()).toBe(true);
        });

        it(`the rollback button should have "${icon}" icon`, () => {
          const button = findRollbackButton();
          expect(button.props().icon).toBe(icon);
        });

        it(`the rollback button should have "${buttonTitle}" title`, () => {
          const button = findRollbackButton();
          expect(button.attributes().title).toBe(buttonTitle);
        });

        it(`the rollback button click should send correct mutation`, async () => {
          const button = findRollbackButton();
          button.vm.$emit('click');
          await waitForPromises();
          expect(mockSetEnvironmentToRollback).toHaveBeenCalledWith(
            expect.anything(),
            { environment: rollback },
            expect.anything(),
            expect.anything(),
          );
        });
      },
    );
  });
});
