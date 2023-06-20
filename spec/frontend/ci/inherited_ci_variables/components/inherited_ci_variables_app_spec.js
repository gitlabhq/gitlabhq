import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import CiVariableTable from '~/ci/ci_variable_list/components/ci_variable_table.vue';
import InheritedCiVariablesApp, {
  i18n,
  FETCH_LIMIT,
  VARIABLES_PER_FETCH,
} from '~/ci/inherited_ci_variables/components/inherited_ci_variables_app.vue';
import getInheritedCiVariables from '~/ci/inherited_ci_variables/graphql/queries/inherited_ci_variables.query.graphql';
import { mockInheritedCiVariables } from '../mocks';

jest.mock('~/alert');
Vue.use(VueApollo);

describe('Inherited CI Variables Component', () => {
  let wrapper;
  let mockApollo;
  let mockVariables;

  const defaultProvide = {
    projectPath: 'namespace/project',
    projectId: '1',
  };

  const findCiTable = () => wrapper.findComponent(CiVariableTable);

  // eslint-disable-next-line consistent-return
  function createComponentWithApollo({ isLoading = false } = {}) {
    const handlers = [[getInheritedCiVariables, mockVariables]];

    mockApollo = createMockApollo(handlers);

    wrapper = shallowMount(InheritedCiVariablesApp, {
      provide: defaultProvide,
      apolloProvider: mockApollo,
    });

    if (!isLoading) {
      return waitForPromises();
    }
  }

  beforeEach(() => {
    mockVariables = jest.fn();
  });

  describe('while variables are being fetched', () => {
    beforeEach(() => {
      mockVariables.mockResolvedValue(mockInheritedCiVariables());
      createComponentWithApollo({ isLoading: true });
    });

    it('shows a loading icon', () => {
      expect(findCiTable().props('isLoading')).toBe(true);
    });
  });

  describe('when there are more variables to fetch', () => {
    beforeEach(async () => {
      mockVariables.mockResolvedValue(mockInheritedCiVariables({ withNextPage: true }));

      await createComponentWithApollo();
    });

    it('re-fetches the query up to <FETCH_LIMIT> times', () => {
      expect(mockVariables).toHaveBeenCalledTimes(FETCH_LIMIT);
    });

    it('shows alert message when calls have exceeded FETCH_LIMIT', () => {
      expect(createAlert).toHaveBeenCalledWith({ message: i18n.tooManyCallsError });
    });
  });

  describe('when variables are fetched successfully', () => {
    beforeEach(async () => {
      mockVariables.mockResolvedValue(mockInheritedCiVariables());

      await createComponentWithApollo();
    });

    it('query was called with the correct arguments', () => {
      expect(mockVariables).toHaveBeenCalledWith({
        first: VARIABLES_PER_FETCH,
        fullPath: defaultProvide.projectPath,
      });
    });

    it('passes down variables to the table component', () => {
      expect(findCiTable().props('variables')).toEqual(
        mockInheritedCiVariables().data.project.inheritedCiVariables.nodes,
      );
    });

    it('createAlert was not called', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });
  });

  describe('when fetch error occurs', () => {
    beforeEach(async () => {
      mockVariables.mockRejectedValue();

      await createComponentWithApollo();
    });

    it('shows alert message with the expected error message', () => {
      expect(createAlert).toHaveBeenCalledWith({ message: i18n.fetchError });
    });
  });
});
