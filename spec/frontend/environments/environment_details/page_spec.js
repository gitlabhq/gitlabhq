import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import resolvedEnvironmentDetails from 'test_fixtures/graphql/environments/graphql/queries/environment_details.query.graphql.json';
import emptyEnvironmentDetails from 'test_fixtures/graphql/environments/graphql/queries/environment_details.query.graphql.empty.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EnvironmentsDetailPage from '~/environments/environment_details/index.vue';
import EmptyState from '~/environments/environment_details/empty_state.vue';
import getEnvironmentDetails from '~/environments/graphql/queries/environment_details.query.graphql';
import createMockApollo from '../../__helpers__/mock_apollo_helper';
import waitForPromises from '../../__helpers__/wait_for_promises';

describe('~/environments/environment_details/page.vue', () => {
  Vue.use(VueApollo);

  let wrapper;

  const defaultWrapperParameters = {
    resolvedData: resolvedEnvironmentDetails,
  };

  const createWrapper = ({ resolvedData } = defaultWrapperParameters) => {
    const mockApollo = createMockApollo([
      [getEnvironmentDetails, jest.fn().mockResolvedValue(resolvedData)],
    ]);

    return mountExtended(EnvironmentsDetailPage, {
      apolloProvider: mockApollo,
      propsData: {
        projectFullPath: 'gitlab-group/test-project',
        environmentName: 'test-environment-name',
      },
    });
  };

  describe('when fetching data', () => {
    it('should show a loading indicator', () => {
      wrapper = createWrapper();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.findComponent(GlTableLite).exists()).not.toBe(true);
    });
  });

  describe('when data is fetched', () => {
    describe('and there are deployments', () => {
      beforeEach(async () => {
        wrapper = createWrapper();
        await waitForPromises();
      });
      it('should render a table when query is loaded', async () => {
        expect(wrapper.findComponent(GlLoadingIcon).exists()).not.toBe(true);
        expect(wrapper.findComponent(GlTableLite).exists()).toBe(true);
      });
    });

    describe('and there are no deployments', () => {
      beforeEach(async () => {
        wrapper = createWrapper({ resolvedData: emptyEnvironmentDetails });
        await waitForPromises();
      });

      it('should render empty state component', async () => {
        expect(wrapper.findComponent(GlTableLite).exists()).toBe(false);
        expect(wrapper.findComponent(EmptyState).exists()).toBe(true);
      });
    });
  });
});
