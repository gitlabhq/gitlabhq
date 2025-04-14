import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import pipelineVariablesPermissionsMixin from '~/ci/mixins/pipeline_variables_permissions_mixin';
import getPipelineVariablesMinimumOverrideRoleQuery from '~/ci/pipeline_variables_minimum_override_role/graphql/queries/get_pipeline_variables_minimum_override_role_project_setting.query.graphql';

Vue.use(VueApollo);
jest.mock('~/alert');

const TestComponent = {
  mixins: [pipelineVariablesPermissionsMixin],
  template: `
    <div>
      <div v-if="pipelineVariablesPermissionsLoading" data-testid="loading-state">Loading…</div>
      <div v-else-if="canViewPipelineVariables" data-testid="authorized-content">Authorized</div>
      <div v-else data-testid="unauthorized-content">Unauthorized</div>
      <div v-if="hasError" data-testid="error-state">Error occurred</div>
    </div>
  `,
};

describe('Pipeline Variables Permissions Mixin', () => {
  let wrapper;
  let minimumRoleHandler;

  const ROLE_NO_ONE = 'no_one_allowed';
  const ROLE_DEVELOPER = 'developer';
  const ROLE_MAINTAINER = 'maintainer';

  const defaultProvide = {
    userRole: ROLE_DEVELOPER,
    projectPath: 'project/path',
  };

  const generateSettingsResponse = (minimumRole = ROLE_DEVELOPER) => ({
    data: {
      project: {
        id: 'gid://gitlab/Project/12',
        ciCdSettings: {
          pipelineVariablesMinimumOverrideRole: minimumRole,
        },
      },
    },
  });

  const createComponent = async ({ provide = {} } = {}) => {
    const handlers = [[getPipelineVariablesMinimumOverrideRoleQuery, minimumRoleHandler]];

    wrapper = shallowMountExtended(TestComponent, {
      apolloProvider: createMockApollo(handlers),
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });

    await waitForPromises();
  };

  const findLoadingState = () => wrapper.findByTestId('loading-state');
  const findAuthorizedContent = () => wrapper.findByTestId('authorized-content');
  const findUnauthorizedContent = () => wrapper.findByTestId('unauthorized-content');
  const findErrorState = () => wrapper.findByTestId('error-state');

  describe('on load', () => {
    describe('when settings query is successful', () => {
      beforeEach(async () => {
        minimumRoleHandler = jest.fn().mockResolvedValue(generateSettingsResponse());
        await createComponent();
      });

      it('fetches data from settings query', () => {
        expect(minimumRoleHandler).toHaveBeenCalledTimes(1);
      });
    });

    describe('when settings query fails', () => {
      beforeEach(async () => {
        minimumRoleHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
        await createComponent();
      });

      it('calls createAlert with the correct message', () => {
        expect(createAlert).toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was a problem fetching the CI/CD settings.',
        });
      });

      it('shows error state', () => {
        expect(findErrorState().exists()).toBe(true);
      });
    });
  });

  describe('during loading state', () => {
    it('shows loading state and not content', async () => {
      minimumRoleHandler = jest.fn().mockImplementation(() => new Promise(() => {}));
      await createComponent();

      expect(findLoadingState().exists()).toBe(true);
      expect(findAuthorizedContent().exists()).toBe(false);
      expect(findUnauthorizedContent().exists()).toBe(false);
    });
  });

  describe('permissions calculations based on user roles', () => {
    it.each`
      scenario                                   | userRole        | minimumRole        | isAuthorized
      ${'user role is lower than minimum role'}  | ${'Developer'}  | ${ROLE_MAINTAINER} | ${false}
      ${'user role is equal to minimum role'}    | ${'Maintainer'} | ${ROLE_MAINTAINER} | ${true}
      ${'user role is higher than minimum role'} | ${'Owner'}      | ${ROLE_MAINTAINER} | ${true}
      ${'user role is higher than minimum role'} | ${''}           | ${ROLE_MAINTAINER} | ${false}
      ${'minimum role is no_one_allowed'}        | ${'Owner'}      | ${ROLE_NO_ONE}     | ${false}
    `(
      'when $scenario, authorization is $isAuthorized',
      async ({ userRole, minimumRole, isAuthorized }) => {
        minimumRoleHandler = jest.fn().mockResolvedValue(generateSettingsResponse(minimumRole));

        await createComponent({
          provide: { userRole },
        });

        expect(findAuthorizedContent().exists()).toBe(isAuthorized);
        expect(findUnauthorizedContent().exists()).toBe(!isAuthorized);
      },
    );
  });
});
