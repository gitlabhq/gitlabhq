import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { resolvers } from '~/ci/ci_variable_list/graphql/settings';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
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
  ENVIRONMENT_QUERY_LIMIT,
  UPDATE_MUTATION_ACTION,
  environmentFetchErrorText,
  genericMutationErrorText,
  variableFetchErrorText,
  mapMutationActionToToast,
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

jest.mock('~/alert');

Vue.use(VueApollo);

const mockProvide = {
  endpoint: '/variables',
  isGroup: false,
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
  let mockVariables;

  const mockToastShow = jest.fn();

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findCiTable = () => wrapper.findComponent(GlTable);
  const findCiSettings = () => wrapper.findComponent(ciVariableSettings);

  // eslint-disable-next-line consistent-return
  function createComponentWithApollo({
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
          expect(createAlert).toHaveBeenCalledWith({ message: environmentFetchErrorText });
        });
      });
    });

    describe('environment query', () => {
      describe('when there is an environment key in queryData', () => {
        beforeEach(() => {
          mockEnvironments
            .mockResolvedValueOnce(mockProjectEnvironments)
            .mockResolvedValueOnce(mockProjectEnvironments);

          mockVariables.mockResolvedValue(mockProjectVariables);
        });

        it('environments are fetched', async () => {
          await createComponentWithApollo({
            props: { ...createProjectProps() },
            provide: pagesFeatureFlagProvide,
          });

          expect(mockEnvironments).toHaveBeenCalled();
        });

        describe('when Limit Environment Scope FF is enabled', () => {
          beforeEach(async () => {
            await createComponentWithApollo({
              props: { ...createProjectProps() },
              provide: {
                glFeatures: {
                  ciLimitEnvironmentScope: true,
                  ciVariablesPages: isVariablePagesEnabled,
                },
              },
            });
          });

          it('initial query is called with the correct variables', () => {
            expect(mockEnvironments).toHaveBeenCalledWith({
              first: ENVIRONMENT_QUERY_LIMIT,
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
        });

        describe('when Limit Environment Scope FF is disabled', () => {
          beforeEach(async () => {
            await createComponentWithApollo({
              props: { ...createProjectProps() },
              provide: pagesFeatureFlagProvide,
            });
          });

          it('initial query is called with the correct variables', async () => {
            expect(mockEnvironments).toHaveBeenCalledWith({ fullPath: '/namespace/project/' });
          });

          it(`does not refetch environments when search term is present`, async () => {
            expect(mockEnvironments).toHaveBeenCalledTimes(1);

            await findCiSettings().vm.$emit('search-environment-scope', 'staging');

            expect(mockEnvironments).toHaveBeenCalledTimes(1);
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

      beforeEach(async () => {
        mockVariables.mockResolvedValue(mockGroupVariables);

        await createComponentWithApollo({
          customHandlers: [[getGroupVariables, mockVariables]],
          props: groupProps,
          provide: pagesFeatureFlagProvide,
        });
      });
      it.each`
        actionName  | mutation                                           | event
        ${'add'}    | ${groupProps.mutationData[ADD_MUTATION_ACTION]}    | ${'add-variable'}
        ${'update'} | ${groupProps.mutationData[UPDATE_MUTATION_ACTION]} | ${'update-variable'}
        ${'delete'} | ${groupProps.mutationData[DELETE_MUTATION_ACTION]} | ${'delete-variable'}
      `(
        'calls the mutation from propsData and shows a toast when user performs $actionName variable',
        async ({ event, mutation, actionName }) => {
          jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({ data: {} });

          await findCiSettings().vm.$emit(event, newVariable);

          expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
            mutation,
            variables: {
              endpoint: mockProvide.endpoint,
              fullPath: groupProps.fullPath,
              id: convertToGraphQLId(TYPENAME_GROUP, groupProps.id),
              variable: newVariable,
            },
          });

          await nextTick();

          expect(mockToastShow).toHaveBeenCalledWith(
            mapMutationActionToToast[actionName](newVariable.key),
          );
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
            provide: pagesFeatureFlagProvide,
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

            await createComponentWithApollo({
              customHandlers,
              props,
              provide: { ...provide, ...pagesFeatureFlagProvide },
            });

            expect(findCiSettings().props()).toEqual({
              areEnvironmentsLoading: false,
              areScopedVariablesAvailable: wrapper.props().areScopedVariablesAvailable,
              hideEnvironmentScope: defaultProps.hideEnvironmentScope,
              pageInfo: defaultProps.pageInfo,
              isLoading: false,
              maxVariableLimit,
              variables: wrapper.props().queryData.ciVariables.lookup(mockVariablesValue.data)
                ?.nodes,
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
            provide: pagesFeatureFlagProvide,
          });

          jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({ data: {} });
          jest
            .spyOn(wrapper.vm.$apollo.queries.ciVariables, 'refetch')
            .mockImplementation(jest.fn());

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

          it('will not mount component with wrong data', async () => {
            try {
              await createComponentWithApollo({
                customHandlers: [[getGroupVariables, mockVariables]],
                props: { ...createGroupProps(), queryData: { wrongKey: {} } },
                provide: pagesFeatureFlagProvide,
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

          it('will not mount component with wrong data', async () => {
            try {
              await createComponentWithApollo({
                props: { ...createGroupProps(), mutationData: { wrongKey: {} } },
                provide: pagesFeatureFlagProvide,
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
});
