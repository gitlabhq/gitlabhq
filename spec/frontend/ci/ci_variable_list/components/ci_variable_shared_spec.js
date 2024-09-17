import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { assertProps } from 'helpers/assert_props';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { resolvers } from '~/ci/ci_variable_list/graphql/settings';

import ciVariableShared from '~/ci/ci_variable_list/components/ci_variable_shared.vue';
import ciVariableSettings from '~/ci/ci_variable_list/components/ci_variable_settings.vue';
import ciVariableTable from '~/ci/ci_variable_list/components/ci_variable_table.vue';
import {
  getProjectEnvironments,
  ENVIRONMENT_FETCH_ERROR,
} from '~/ci/common/private/ci_environments_dropdown';
import getAdminVariables from '~/ci/ci_variable_list/graphql/queries/variables.query.graphql';
import getGroupVariables from '~/ci/ci_variable_list/graphql/queries/group_variables.query.graphql';
import getProjectVariables from '~/ci/ci_variable_list/graphql/queries/project_variables.query.graphql';
import { genericMutationErrorText, variableFetchErrorText } from '~/ci/ci_variable_list/constants';

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

jest.mock('~/alert');

Vue.use(VueApollo);

const mockProvide = {
  endpoint: '/variables',
  isGroup: false,
  isInheritedGroupVars: false,
  isProject: false,
};

const defaultProps = {
  areScopedVariablesAvailable: true,
  pageInfo: {},
  hideEnvironmentScope: false,
  refetchAfterMutation: false,
};

describe('Ci Variable Shared Component', () => {
  let wrapper;

  let mockApollo;
  let mockEnvironments;
  let mockMutation;
  let mockAddMutation;
  let mockUpdateMutation;
  let mockDeleteMutation;
  let mockVariables;

  const mockToastShow = jest.fn();

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findCiTable = () => wrapper.findComponent(GlTable);
  const findCiSettings = () => wrapper.findComponent(ciVariableSettings);

  // eslint-disable-next-line consistent-return
  function createComponentWithApollo({
    customHandlers = null,
    customResolvers = null,
    isLoading = false,
    props = { ...createProjectProps() },
    provide = {},
  } = {}) {
    const handlers = customHandlers || [
      [getProjectEnvironments, mockEnvironments],
      [getProjectVariables, mockVariables],
    ];

    const mutationResolvers = customResolvers || resolvers;

    mockApollo = createMockApollo(handlers, mutationResolvers);

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
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });

    if (!isLoading) {
      return waitForPromises();
    }
  }

  beforeEach(() => {
    mockEnvironments = jest.fn();
    mockVariables = jest.fn();
    mockMutation = jest.fn();
    mockAddMutation = jest.fn();
    mockUpdateMutation = jest.fn();
    mockDeleteMutation = jest.fn();
  });

  describe.each`
    isVariablePagesEnabled | text
    ${true}                | ${'enabled'}
    ${false}               | ${'disabled'}
  `('When Pages FF is $text', ({ isVariablePagesEnabled }) => {
    const pagesFeatureFlagProvide = isVariablePagesEnabled
      ? { glFeatures: { ciVariablesPages: true } }
      : {};

    describe('while queries are being fetched', () => {
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

          await createComponentWithApollo({
            provide: { ...createProjectProvide(), ...pagesFeatureFlagProvide },
          });
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

          await createComponentWithApollo({ provide: pagesFeatureFlagProvide });
        });

        it('calls createAlert with the expected error message', () => {
          expect(createAlert).toHaveBeenCalledWith({ message: variableFetchErrorText });
        });
      });

      describe('with an error for environments', () => {
        beforeEach(async () => {
          mockEnvironments.mockRejectedValue();
          mockVariables.mockResolvedValue(mockProjectVariables);

          await createComponentWithApollo({ provide: pagesFeatureFlagProvide });
        });

        it('calls createAlert with the expected error message', () => {
          expect(createAlert).toHaveBeenCalledWith({ message: ENVIRONMENT_FETCH_ERROR });
        });
      });
    });

    describe('environment query', () => {
      describe('when there is an environment key in queryData', () => {
        beforeEach(() => {
          mockEnvironments.mockResolvedValue(mockProjectEnvironments);

          mockVariables.mockResolvedValue(mockProjectVariables);
        });

        it('environments are fetched', async () => {
          await createComponentWithApollo({
            props: { ...createProjectProps() },
            provide: pagesFeatureFlagProvide,
          });

          expect(mockEnvironments).toHaveBeenCalled();
        });

        // applies only to project-level CI variables
        describe('when environment scope is limited', () => {
          beforeEach(async () => {
            await createComponentWithApollo({
              props: { ...createProjectProps() },
              provide: pagesFeatureFlagProvide,
            });
          });

          it('initial query is called with the correct variables', () => {
            expect(mockEnvironments).toHaveBeenCalledWith({
              first: 30,
              fullPath: '/namespace/project/',
              search: '',
            });
          });

          it(`refetches environments when search term is present`, async () => {
            expect(mockEnvironments).toHaveBeenCalledTimes(1);
            expect(mockEnvironments).toHaveBeenCalledWith(expect.objectContaining({ search: '' }));

            await findCiSettings().vm.$emit('search-environment-scope', 'staging');

            expect(mockEnvironments).toHaveBeenCalledTimes(2);
            expect(mockEnvironments).toHaveBeenCalledWith(
              expect.objectContaining({ search: 'staging' }),
            );
          });

          it('does not show loading icon in table while searching for environments', () => {
            findCiSettings().vm.$emit('search-environment-scope', 'staging');

            expect(findLoadingIcon().exists()).toBe(false);
          });
        });
      });

      describe("when there isn't an environment key in queryData", () => {
        beforeEach(async () => {
          mockVariables.mockResolvedValue(mockGroupVariables);

          await createComponentWithApollo({
            props: { ...createGroupProps() },
            provide: pagesFeatureFlagProvide,
          });
        });

        it('fetching environments is skipped', () => {
          expect(mockEnvironments).not.toHaveBeenCalled();
        });
      });
    });

    describe('mutations', () => {
      const groupProps = createGroupProps();
      const instanceProps = createInstanceProps();
      const projectProps = createProjectProps();

      let mockMutationMap;

      describe('error handling and feedback', () => {
        beforeEach(async () => {
          mockVariables.mockResolvedValue(mockGroupVariables);
          mockMutation.mockResolvedValue({ ...mockGroupVariables.data, errors: [] });

          await createComponentWithApollo({
            customHandlers: [[getGroupVariables, mockVariables]],
            customResolvers: {
              Mutation: {
                ...resolvers.Mutation,
                addGroupVariable: mockMutation,
                updateGroupVariable: mockMutation,
                deleteGroupVariable: mockMutation,
              },
            },
            props: groupProps,
            provide: pagesFeatureFlagProvide,
          });
        });

        it('throws the specific graphql error if present when user deletes variable', async () => {
          const graphQLErrorMessage = 'There is a problem with this graphQL action';
          mockMutation.mockResolvedValue({
            ...mockGroupVariables.data,
            errors: [graphQLErrorMessage],
          });

          await findCiSettings().vm.$emit('delete-variable', newVariable);
          await waitForPromises();

          expect(mockMutation).toHaveBeenCalled();
          expect(createAlert).toHaveBeenCalledWith({ message: graphQLErrorMessage });
        });

        it('throws generic error on failure with no graphql errors and user deletes variable', async () => {
          mockMutation.mockRejectedValue();

          await findCiSettings().vm.$emit('delete-variable', newVariable);
          await waitForPromises();

          expect(mockMutation).toHaveBeenCalled();
          expect(createAlert).toHaveBeenCalledWith({ message: genericMutationErrorText });
        });

        it('displays toast message after user deletes variable', async () => {
          await findCiSettings().vm.$emit('delete-variable', newVariable);
          await waitForPromises();

          expect(mockMutation).toHaveBeenCalled();
          expect(mockToastShow).toHaveBeenCalledWith(
            `Variable ${newVariable.key} has been deleted.`,
          );
        });
      });

      const setupMockMutations = (mockResolvedMutation) => {
        mockAddMutation.mockResolvedValue(mockResolvedMutation);
        mockUpdateMutation.mockResolvedValue(mockResolvedMutation);
        mockDeleteMutation.mockResolvedValue(mockResolvedMutation);

        return {
          add: mockAddMutation,
          update: mockUpdateMutation,
          delete: mockDeleteMutation,
        };
      };

      describe.each`
        scope         | mockVariablesResolvedValue | getVariablesHandler    | addMutationName         | updateMutationName         | deleteMutationName         | props
        ${'instance'} | ${mockVariables}           | ${getAdminVariables}   | ${'addAdminVariable'}   | ${'updateAdminVariable'}   | ${'deleteAdminVariable'}   | ${instanceProps}
        ${'group'}    | ${mockGroupVariables}      | ${getGroupVariables}   | ${'addGroupVariable'}   | ${'updateGroupVariable'}   | ${'deleteGroupVariable'}   | ${groupProps}
        ${'project'}  | ${mockProjectVariables}    | ${getProjectVariables} | ${'addProjectVariable'} | ${'updateProjectVariable'} | ${'deleteProjectVariable'} | ${projectProps}
      `(
        '$scope variable mutations',
        ({
          addMutationName,
          deleteMutationName,
          getVariablesHandler,
          mockVariablesResolvedValue,
          updateMutationName,
          props,
        }) => {
          beforeEach(async () => {
            mockVariables.mockResolvedValue(mockVariablesResolvedValue);
            mockMutationMap = setupMockMutations({ ...mockVariables.data, errors: [] });

            await createComponentWithApollo({
              customHandlers: [[getVariablesHandler, mockVariables]],
              customResolvers: {
                Mutation: {
                  ...resolvers.Mutation,
                  [addMutationName]: mockAddMutation,
                  [updateMutationName]: mockUpdateMutation,
                  [deleteMutationName]: mockDeleteMutation,
                },
              },
              props,
              provide: pagesFeatureFlagProvide,
            });
          });

          it.each`
            actionName  | event
            ${'add'}    | ${'add-variable'}
            ${'update'} | ${'update-variable'}
            ${'delete'} | ${'delete-variable'}
          `(
            'calls the right mutation when user performs $actionName variable',
            async ({ event, actionName }) => {
              await findCiSettings().vm.$emit(event, newVariable);
              await waitForPromises();

              expect(mockMutationMap[actionName]).toHaveBeenCalledWith(
                expect.anything(),
                {
                  endpoint: mockProvide.endpoint,
                  fullPath: props.fullPath,
                  id: props.id,
                  variable: newVariable,
                },
                expect.anything(),
                expect.anything(),
              );
            },
          );
        },
      );

      describe('without fullpath and ID props', () => {
        beforeEach(async () => {
          mockMutation.mockResolvedValue({ ...mockAdminVariables.data, errors: [] });
          mockVariables.mockResolvedValue(mockAdminVariables);

          await createComponentWithApollo({
            customHandlers: [[getAdminVariables, mockVariables]],
            customResolvers: {
              Mutation: {
                ...resolvers.Mutation,
                addAdminVariable: mockMutation,
              },
            },
            props: createInstanceProps(),
            provide: pagesFeatureFlagProvide,
          });
        });

        it('does not pass fullPath and ID to the mutation', async () => {
          await findCiSettings().vm.$emit('add-variable', newVariable);
          await waitForPromises();

          expect(mockMutation).toHaveBeenCalledWith(
            expect.anything(),
            {
              endpoint: mockProvide.endpoint,
              variable: newVariable,
            },
            expect.anything(),
            expect.anything(),
          );
        });
      });
    });

    describe('Props', () => {
      const mockGroupCiVariables = mockGroupVariables.data.group.ciVariables;
      const mockProjectCiVariables = mockProjectVariables.data.project.ciVariables;

      const projectVariablesContext = {
        mockVariablesValue: mockProjectVariables,
        mockEnvironmentsValue: mockProjectEnvironments,
        withEnvironments: true,
        expectedEnvironments: ['prod', 'dev'],
        propsFn: createProjectProps,
        provideFn: createProjectProvide,
        mutation: null,
        maxVariableLimit: mockProjectCiVariables.limit,
      };

      const groupVariablesContext = {
        mockVariablesValue: mockGroupVariables,
        mockEnvironmentsValue: [],
        withEnvironments: false,
        expectedEnvironments: [],
        propsFn: createGroupProps,
        provideFn: createGroupProvide,
        mutation: getGroupVariables,
        maxVariableLimit: mockGroupCiVariables.limit,
      };

      const instanceVariablesContext = {
        mockVariablesValue: mockAdminVariables,
        mockEnvironmentsValue: [],
        withEnvironments: false,
        expectedEnvironments: [],
        propsFn: createInstanceProps,
        provideFn: () => {},
        mutation: getAdminVariables,
        maxVariableLimit: 0,
      };

      describe('in a specific context as', () => {
        it.each`
          name          | context
          ${'project'}  | ${projectVariablesContext}
          ${'group'}    | ${groupVariablesContext}
          ${'instance'} | ${instanceVariablesContext}
        `('passes down all the required props when its a $name component', async ({ context }) => {
          const props = context.propsFn();
          const provide = context.provideFn();

          mockVariables.mockResolvedValue(context.mockVariablesValue);

          if (context.withEnvironments) {
            mockEnvironments.mockResolvedValue(context.mockEnvironmentsValue);
          }

          let customHandlers = null;

          if (context.mutation) {
            customHandlers = [[context.mutation, mockVariables]];
          }

          await createComponentWithApollo({
            customHandlers,
            props,
            provide: { ...provide, ...pagesFeatureFlagProvide },
          });

          expect(findCiSettings().props()).toMatchObject({
            areEnvironmentsLoading: false,
            areScopedVariablesAvailable: wrapper.props().areScopedVariablesAvailable,
            entity: props.entity,
            environments: context.expectedEnvironments,
            hideEnvironmentScope: defaultProps.hideEnvironmentScope,
            isLoading: false,
            pageInfo: defaultProps.pageInfo,
            mutationResponse: null,
            maxVariableLimit: context.maxVariableLimit,
            variables: wrapper.props().queryData.ciVariables.lookup(context.mockVariablesValue.data)
              ?.nodes,
          });
        });
      });

      describe('refetchAfterMutation', () => {
        it.each`
          bool     | text                                | timesQueryCalled
          ${true}  | ${'refetches the variables'}        | ${2}
          ${false} | ${'does not refetch the variables'} | ${1}
        `('when $bool it $text', async ({ bool, timesQueryCalled }) => {
          mockMutation.mockResolvedValue({ ...mockAdminVariables.data, errors: [] });
          mockVariables.mockResolvedValue(mockAdminVariables);

          await createComponentWithApollo({
            customHandlers: [[getAdminVariables, mockVariables]],
            customResolvers: {
              Mutation: {
                ...resolvers.Mutation,
                addAdminVariable: mockMutation,
              },
            },
            props: { ...createInstanceProps(), refetchAfterMutation: bool },
            provide: pagesFeatureFlagProvide,
          });

          await findCiSettings().vm.$emit('add-variable', newVariable);
          await waitForPromises();

          expect(mockVariables).toHaveBeenCalledTimes(timesQueryCalled);
        });
      });

      describe('Validators', () => {
        describe('queryData', () => {
          let error;

          beforeEach(() => {
            mockVariables.mockResolvedValue(mockGroupVariables);
          });

          it('will mount component with right data', async () => {
            try {
              await createComponentWithApollo({
                customHandlers: [[getGroupVariables, mockVariables]],
                props: { ...createGroupProps() },
                provide: pagesFeatureFlagProvide,
              });
            } catch (e) {
              error = e;
            } finally {
              expect(wrapper.exists()).toBe(true);
              expect(error).toBeUndefined();
            }
          });

          it('report custom validator error on wrong data', () => {
            expect(() =>
              assertProps(
                ciVariableShared,
                { ...defaultProps, ...createGroupProps(), queryData: { wrongKey: {} } },
                { provide: mockProvide },
              ),
            ).toThrow('custom validator check failed for prop');
          });
        });

        describe('mutationData', () => {
          let error;

          beforeEach(() => {
            mockVariables.mockResolvedValue(mockGroupVariables);
          });

          it('will mount component with right data', async () => {
            try {
              await createComponentWithApollo({
                props: { ...createGroupProps() },
                provide: pagesFeatureFlagProvide,
              });
            } catch (e) {
              error = e;
            } finally {
              expect(wrapper.exists()).toBe(true);
              expect(error).toBeUndefined();
            }
          });

          it('report custom validator error on wrong data', () => {
            expect(() =>
              assertProps(
                ciVariableShared,
                { ...defaultProps, ...createGroupProps(), mutationData: { wrongKey: {} } },
                { provide: { ...mockProvide, ...pagesFeatureFlagProvide } },
              ),
            ).toThrow('custom validator check failed for prop');
          });
        });
      });
    });
  });
});
