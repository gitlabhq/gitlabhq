import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import { resolvers } from '~/ci/ci_variable_list/graphql/settings';
import { convertToGraphQLId } from '~/graphql_shared/utils';

import ciVariableShared from '~/ci/ci_variable_list/components/ci_variable_shared.vue';
import ciVariableSettings from '~/ci/ci_variable_list/components/ci_variable_settings.vue';
import ciVariableTable from '~/ci/ci_variable_list/components/ci_variable_table.vue';
import getProjectEnvironments from '~/ci/ci_variable_list/graphql/queries/project_environments.query.graphql';
import getAdminVariables from '~/ci/ci_variable_list/graphql/queries/variables.query.graphql';
import getGroupVariables from '~/ci/ci_variable_list/graphql/queries/group_variables.query.graphql';
import getProjectVariables from '~/ci/ci_variable_list/graphql/queries/project_variables.query.graphql';

import {
  ADD_MUTATION_ACTION,
  DELETE_MUTATION_ACTION,
  UPDATE_MUTATION_ACTION,
  environmentFetchErrorText,
  genericMutationErrorText,
  variableFetchErrorText,
} from '~/ci/ci_variable_list/constants';

import {
  createGroupProps,
  createInstanceProps,
  createProjectProps,
  createGroupProvide,
  createProjectProvide,
  devName,
  mockProjectEnvironments,
  mockProjectVariables,
  newVariable,
  prodName,
  mockGroupVariables,
  mockAdminVariables,
} from '../mocks';

jest.mock('~/flash');

Vue.use(VueApollo);

const mockProvide = {
  endpoint: '/variables',
  isGroup: false,
  isProject: false,
};

const defaultProps = {
  areScopedVariablesAvailable: true,
  hideEnvironmentScope: false,
  refetchAfterMutation: false,
};

describe('Ci Variable Shared Component', () => {
  let wrapper;

  let mockApollo;
  let mockEnvironments;
  let mockVariables;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findCiTable = () => wrapper.findComponent(GlTable);
  const findCiSettings = () => wrapper.findComponent(ciVariableSettings);

  // eslint-disable-next-line consistent-return
  async function createComponentWithApollo({
    customHandlers = null,
    isLoading = false,
    props = { ...createProjectProps() },
    provide = {},
  } = {}) {
    const handlers = customHandlers || [
      [getProjectEnvironments, mockEnvironments],
      [getProjectVariables, mockVariables],
    ];

    mockApollo = createMockApollo(handlers, resolvers);

    wrapper = shallowMount(ciVariableShared, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...mockProvide,
        ...provide,
      },
      apolloProvider: mockApollo,
      stubs: { ciVariableSettings, ciVariableTable },
    });

    if (!isLoading) {
      return waitForPromises();
    }
  }

  beforeEach(() => {
    mockEnvironments = jest.fn();
    mockVariables = jest.fn();
  });

  describe('while queries are being fetch', () => {
    beforeEach(() => {
      createComponentWithApollo({ isLoading: true });
    });

    it('shows a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findCiTable().exists()).toBe(false);
    });
  });

  describe('when queries are resolved', () => {
    describe('successfully', () => {
      beforeEach(async () => {
        mockEnvironments.mockResolvedValue(mockProjectEnvironments);
        mockVariables.mockResolvedValue(mockProjectVariables);

        await createComponentWithApollo({ provide: createProjectProvide() });
      });

      it('passes down the expected max variable limit as props', () => {
        expect(findCiSettings().props('maxVariableLimit')).toBe(
          mockProjectVariables.data.project.ciVariables.limit,
        );
      });

      it('passes down the expected environments as props', () => {
        expect(findCiSettings().props('environments')).toEqual([prodName, devName]);
      });

      it('passes down the expected variables as props', () => {
        expect(findCiSettings().props('variables')).toEqual(
          mockProjectVariables.data.project.ciVariables.nodes,
        );
      });

      it('createAlert was not called', () => {
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('with an error for variables', () => {
      beforeEach(async () => {
        mockEnvironments.mockResolvedValue(mockProjectEnvironments);
        mockVariables.mockRejectedValue();

        await createComponentWithApollo();
      });

      it('calls createAlert with the expected error message', () => {
        expect(createAlert).toHaveBeenCalledWith({ message: variableFetchErrorText });
      });
    });

    describe('with an error for environments', () => {
      beforeEach(async () => {
        mockEnvironments.mockRejectedValue();
        mockVariables.mockResolvedValue(mockProjectVariables);

        await createComponentWithApollo();
      });

      it('calls createAlert with the expected error message', () => {
        expect(createAlert).toHaveBeenCalledWith({ message: environmentFetchErrorText });
      });
    });
  });

  describe('environment query', () => {
    describe('when there is an environment key in queryData', () => {
      beforeEach(async () => {
        mockEnvironments.mockResolvedValue(mockProjectEnvironments);
        mockVariables.mockResolvedValue(mockProjectVariables);

        await createComponentWithApollo({ props: { ...createProjectProps() } });
      });

      it('is executed', () => {
        expect(mockVariables).toHaveBeenCalled();
      });
    });

    describe('when there isnt an environment key in queryData', () => {
      beforeEach(async () => {
        mockVariables.mockResolvedValue(mockGroupVariables);

        await createComponentWithApollo({ props: { ...createGroupProps() } });
      });

      it('is skipped', () => {
        expect(mockVariables).not.toHaveBeenCalled();
      });
    });
  });

  describe('mutations', () => {
    const groupProps = createGroupProps();

    beforeEach(async () => {
      mockVariables.mockResolvedValue(mockGroupVariables);

      await createComponentWithApollo({
        customHandlers: [[getGroupVariables, mockVariables]],
        props: groupProps,
      });
    });
    it.each`
      actionName  | mutation                                           | event
      ${'add'}    | ${groupProps.mutationData[ADD_MUTATION_ACTION]}    | ${'add-variable'}
      ${'update'} | ${groupProps.mutationData[UPDATE_MUTATION_ACTION]} | ${'update-variable'}
      ${'delete'} | ${groupProps.mutationData[DELETE_MUTATION_ACTION]} | ${'delete-variable'}
    `(
      'calls the right mutation from propsData when user performs $actionName variable',
      async ({ event, mutation }) => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue();

        await findCiSettings().vm.$emit(event, newVariable);

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation,
          variables: {
            endpoint: mockProvide.endpoint,
            fullPath: groupProps.fullPath,
            id: convertToGraphQLId('Group', groupProps.id),
            variable: newVariable,
          },
        });
      },
    );

    it.each`
      actionName  | event
      ${'add'}    | ${'add-variable'}
      ${'update'} | ${'update-variable'}
      ${'delete'} | ${'delete-variable'}
    `(
      'throws with the specific graphql error if present when user performs $actionName variable',
      async ({ event }) => {
        const graphQLErrorMessage = 'There is a problem with this graphQL action';
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockResolvedValue({ data: { ciVariableMutation: { errors: [graphQLErrorMessage] } } });
        await findCiSettings().vm.$emit(event, newVariable);
        await nextTick();

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({ message: graphQLErrorMessage });
      },
    );

    it.each`
      actionName  | event
      ${'add'}    | ${'add-variable'}
      ${'update'} | ${'update-variable'}
      ${'delete'} | ${'delete-variable'}
    `(
      'throws generic error on failure with no graphql errors and user performs $actionName variable',
      async ({ event }) => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockImplementationOnce(() => {
          throw new Error();
        });
        await findCiSettings().vm.$emit(event, newVariable);

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({ message: genericMutationErrorText });
      },
    );

    describe('without fullpath and ID props', () => {
      beforeEach(async () => {
        mockVariables.mockResolvedValue(mockAdminVariables);

        await createComponentWithApollo({
          customHandlers: [[getAdminVariables, mockVariables]],
          props: createInstanceProps(),
        });
      });

      it('does not pass fullPath and ID to the mutation', async () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue();

        await findCiSettings().vm.$emit('add-variable', newVariable);

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: wrapper.props().mutationData[ADD_MUTATION_ACTION],
          variables: {
            endpoint: mockProvide.endpoint,
            variable: newVariable,
          },
        });
      });
    });
  });

  describe('Props', () => {
    const mockGroupCiVariables = mockGroupVariables.data.group.ciVariables;
    const mockProjectCiVariables = mockProjectVariables.data.project.ciVariables;

    describe('in a specific context as', () => {
      it.each`
        name          | mockVariablesValue      | mockEnvironmentsValue      | withEnvironments | expectedEnvironments | propsFn                | provideFn               | mutation             | maxVariableLimit
        ${'project'}  | ${mockProjectVariables} | ${mockProjectEnvironments} | ${true}          | ${['prod', 'dev']}   | ${createProjectProps}  | ${createProjectProvide} | ${null}              | ${mockProjectCiVariables.limit}
        ${'group'}    | ${mockGroupVariables}   | ${[]}                      | ${false}         | ${[]}                | ${createGroupProps}    | ${createGroupProvide}   | ${getGroupVariables} | ${mockGroupCiVariables.limit}
        ${'instance'} | ${mockAdminVariables}   | ${[]}                      | ${false}         | ${[]}                | ${createInstanceProps} | ${() => {}}             | ${getAdminVariables} | ${0}
      `(
        'passes down all the required props when its a $name component',
        async ({
          mutation,
          maxVariableLimit,
          mockVariablesValue,
          mockEnvironmentsValue,
          withEnvironments,
          expectedEnvironments,
          propsFn,
          provideFn,
        }) => {
          const props = propsFn();
          const provide = provideFn();

          mockVariables.mockResolvedValue(mockVariablesValue);

          if (withEnvironments) {
            mockEnvironments.mockResolvedValue(mockEnvironmentsValue);
          }

          let customHandlers = null;

          if (mutation) {
            customHandlers = [[mutation, mockVariables]];
          }

          await createComponentWithApollo({ customHandlers, props, provide });

          expect(findCiSettings().props()).toEqual({
            areScopedVariablesAvailable: wrapper.props().areScopedVariablesAvailable,
            hideEnvironmentScope: defaultProps.hideEnvironmentScope,
            isLoading: false,
            maxVariableLimit,
            variables: wrapper.props().queryData.ciVariables.lookup(mockVariablesValue.data)?.nodes,
            entity: props.entity,
            environments: expectedEnvironments,
          });
        },
      );
    });

    describe('refetchAfterMutation', () => {
      it.each`
        bool     | text
        ${true}  | ${'refetches the variables'}
        ${false} | ${'does not refetch the variables'}
      `('when $bool it $text', async ({ bool }) => {
        await createComponentWithApollo({
          props: { ...createInstanceProps(), refetchAfterMutation: bool },
        });

        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({ data: {} });
        jest.spyOn(wrapper.vm.$apollo.queries.ciVariables, 'refetch').mockImplementation(jest.fn());

        await findCiSettings().vm.$emit('add-variable', newVariable);

        await nextTick();

        if (bool) {
          expect(wrapper.vm.$apollo.queries.ciVariables.refetch).toHaveBeenCalled();
        } else {
          expect(wrapper.vm.$apollo.queries.ciVariables.refetch).not.toHaveBeenCalled();
        }
      });
    });

    describe('Validators', () => {
      describe('queryData', () => {
        let error;

        beforeEach(async () => {
          mockVariables.mockResolvedValue(mockGroupVariables);
        });

        it('will mount component with right data', async () => {
          try {
            await createComponentWithApollo({
              customHandlers: [[getGroupVariables, mockVariables]],
              props: { ...createGroupProps() },
            });
          } catch (e) {
            error = e;
          } finally {
            expect(wrapper.exists()).toBe(true);
            expect(error).toBeUndefined();
          }
        });

        it('will not mount component with wrong data', async () => {
          try {
            await createComponentWithApollo({
              customHandlers: [[getGroupVariables, mockVariables]],
              props: { ...createGroupProps(), queryData: { wrongKey: {} } },
            });
          } catch (e) {
            error = e;
          } finally {
            expect(wrapper.exists()).toBe(false);
            expect(error.toString()).toContain('custom validator check failed for prop');
          }
        });
      });

      describe('mutationData', () => {
        let error;

        beforeEach(async () => {
          mockVariables.mockResolvedValue(mockGroupVariables);
        });

        it('will mount component with right data', async () => {
          try {
            await createComponentWithApollo({
              props: { ...createGroupProps() },
            });
          } catch (e) {
            error = e;
          } finally {
            expect(wrapper.exists()).toBe(true);
            expect(error).toBeUndefined();
          }
        });

        it('will not mount component with wrong data', async () => {
          try {
            await createComponentWithApollo({
              props: { ...createGroupProps(), mutationData: { wrongKey: {} } },
            });
          } catch (e) {
            error = e;
          } finally {
            expect(wrapper.exists()).toBe(false);
            expect(error.toString()).toContain('custom validator check failed for prop');
          }
        });
      });
    });
  });
});
