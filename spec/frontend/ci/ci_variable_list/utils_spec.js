import { validateQueryData, validateMutationData } from '~/ci/ci_variable_list/utils';
import {
  ADD_MUTATION_ACTION,
  DELETE_MUTATION_ACTION,
  UPDATE_MUTATION_ACTION,
} from '~/ci/ci_variable_list/constants';

describe('validateQueryData', () => {
  describe.each`
    scenario                                          | source                                                                                                                                          | expected
    ${'valid ciVariables without environments'}       | ${{ ciVariables: { lookup: jest.fn(), query: {} } }}                                                                                            | ${true}
    ${'valid ciVariables and environments'}           | ${{ ciVariables: { lookup: jest.fn(), query: {} }, environments: { lookup: jest.fn(), query: {} } }}                                            | ${true}
    ${'query objects with properties'}                | ${{ ciVariables: { lookup: jest.fn(), query: { id: '1', data: 'test' } }, environments: { lookup: jest.fn(), query: { name: 'production' } } }} | ${true}
    ${'arrow functions as lookup methods'}            | ${{ ciVariables: { lookup: () => {}, query: {} } }}                                                                                             | ${true}
    ${'async functions as lookup methods'}            | ${{ ciVariables: { lookup: async () => {}, query: {} }, environments: { lookup: async () => {}, query: {} } }}                                  | ${true}
    ${'missing ciVariables'}                          | ${{}}                                                                                                                                           | ${false}
    ${'null ciVariables'}                             | ${{ ciVariables: null }}                                                                                                                        | ${false}
    ${'undefined ciVariables'}                        | ${{ ciVariables: undefined }}                                                                                                                   | ${false}
    ${'ciVariables.lookup is not a function'}         | ${{ ciVariables: { lookup: 'not a function', query: {} } }}                                                                                     | ${false}
    ${'missing ciVariables.lookup'}                   | ${{ ciVariables: { query: {} } }}                                                                                                               | ${false}
    ${'ciVariables.query is not an object (string)'}  | ${{ ciVariables: { lookup: jest.fn(), query: 'not an object' } }}                                                                               | ${false}
    ${'ciVariables.query is null'}                    | ${{ ciVariables: { lookup: jest.fn(), query: null } }}                                                                                          | ${false}
    ${'missing ciVariables.query'}                    | ${{ ciVariables: { lookup: jest.fn() } }}                                                                                                       | ${false}
    ${'environments.lookup is not a function'}        | ${{ ciVariables: { lookup: jest.fn(), query: {} }, environments: { lookup: 'not a function', query: {} } }}                                     | ${false}
    ${'missing environments.lookup'}                  | ${{ ciVariables: { lookup: jest.fn(), query: {} }, environments: { query: {} } }}                                                               | ${false}
    ${'environments.query is not an object (string)'} | ${{ ciVariables: { lookup: jest.fn(), query: {} }, environments: { lookup: jest.fn(), query: 'not an object' } }}                               | ${false}
    ${'environments.query is null'}                   | ${{ ciVariables: { lookup: jest.fn(), query: {} }, environments: { lookup: jest.fn(), query: null } }}                                          | ${false}
    ${'missing environments.query'}                   | ${{ ciVariables: { lookup: jest.fn(), query: {} }, environments: { lookup: jest.fn() } }}                                                       | ${false}
    ${'environments is an empty object'}              | ${{ ciVariables: { lookup: jest.fn(), query: {} }, environments: {} }}                                                                          | ${false}
    ${'environments is null'}                         | ${{ ciVariables: { lookup: jest.fn(), query: {} }, environments: null }}                                                                        | ${true}
    ${'source is null'}                               | ${null}                                                                                                                                         | ${false}
    ${'source is undefined'}                          | ${undefined}                                                                                                                                    | ${false}
    ${'source is an empty object'}                    | ${{}}                                                                                                                                           | ${false}
  `('$scenario', ({ source, expected }) => {
    it(`returns ${expected}`, () => {
      expect(validateQueryData(source)).toBe(expected);
    });
  });
});

describe('validateMutationData', () => {
  describe.each`
    scenario                                                    | source                                                                                                                                                                          | expected
    ${'all required mutation actions with object values'}       | ${{ [ADD_MUTATION_ACTION]: { mutation: 'add' }, [UPDATE_MUTATION_ACTION]: { mutation: 'update' }, [DELETE_MUTATION_ACTION]: { mutation: 'delete' } }}                           | ${true}
    ${'mutation objects are empty'}                             | ${{ [ADD_MUTATION_ACTION]: {}, [UPDATE_MUTATION_ACTION]: {}, [DELETE_MUTATION_ACTION]: {} }}                                                                                    | ${true}
    ${'mutation objects with nested properties'}                | ${{ [ADD_MUTATION_ACTION]: { query: { id: 1 }, variables: { key: 'value' } }, [UPDATE_MUTATION_ACTION]: { query: { id: 2 } }, [DELETE_MUTATION_ACTION]: { query: { id: 3 } } }} | ${true}
    ${'extra keys along with required ones'}                    | ${{ [ADD_MUTATION_ACTION]: {}, [UPDATE_MUTATION_ACTION]: {}, [DELETE_MUTATION_ACTION]: {}, extraKey: {} }}                                                                      | ${true}
    ${'Date objects as values'}                                 | ${{ [ADD_MUTATION_ACTION]: new Date(), [UPDATE_MUTATION_ACTION]: {}, [DELETE_MUTATION_ACTION]: {} }}                                                                            | ${true}
    ${'nested objects as values'}                               | ${{ [ADD_MUTATION_ACTION]: { nested: { deep: { value: 1 } } }, [UPDATE_MUTATION_ACTION]: { another: { nested: true } }, [DELETE_MUTATION_ACTION]: { data: { id: 1 } } }}        | ${true}
    ${'missing ADD_MUTATION_ACTION'}                            | ${{ [UPDATE_MUTATION_ACTION]: {}, [DELETE_MUTATION_ACTION]: {} }}                                                                                                               | ${true}
    ${'missing UPDATE_MUTATION_ACTION'}                         | ${{ [ADD_MUTATION_ACTION]: {}, [DELETE_MUTATION_ACTION]: {} }}                                                                                                                  | ${true}
    ${'missing DELETE_MUTATION_ACTION'}                         | ${{ [ADD_MUTATION_ACTION]: {}, [UPDATE_MUTATION_ACTION]: {} }}                                                                                                                  | ${true}
    ${'empty object'}                                           | ${{}}                                                                                                                                                                           | ${false}
    ${'extra keys but missing required ones'}                   | ${{ someOtherKey: {}, anotherKey: {} }}                                                                                                                                         | ${false}
    ${'ADD_MUTATION_ACTION value is not an object (string)'}    | ${{ [ADD_MUTATION_ACTION]: 'not an object', [UPDATE_MUTATION_ACTION]: {}, [DELETE_MUTATION_ACTION]: {} }}                                                                       | ${false}
    ${'UPDATE_MUTATION_ACTION value is not an object (number)'} | ${{ [ADD_MUTATION_ACTION]: {}, [UPDATE_MUTATION_ACTION]: 123, [DELETE_MUTATION_ACTION]: {} }}                                                                                   | ${false}
    ${'DELETE_MUTATION_ACTION value is null'}                   | ${{ [ADD_MUTATION_ACTION]: {}, [UPDATE_MUTATION_ACTION]: {}, [DELETE_MUTATION_ACTION]: null }}                                                                                  | ${false}
    ${'multiple values are not objects'}                        | ${{ [ADD_MUTATION_ACTION]: 'string', [UPDATE_MUTATION_ACTION]: null, [DELETE_MUTATION_ACTION]: undefined }}                                                                     | ${false}
    ${'value is an array'}                                      | ${{ [ADD_MUTATION_ACTION]: [], [UPDATE_MUTATION_ACTION]: {}, [DELETE_MUTATION_ACTION]: {} }}                                                                                    | ${false}
    ${'value is a function'}                                    | ${{ [ADD_MUTATION_ACTION]: {}, [UPDATE_MUTATION_ACTION]: jest.fn(), [DELETE_MUTATION_ACTION]: {} }}                                                                             | ${false}
    ${'extra keys with invalid values'}                         | ${{ [ADD_MUTATION_ACTION]: {}, [UPDATE_MUTATION_ACTION]: {}, [DELETE_MUTATION_ACTION]: {}, extraKey: 'invalid' }}                                                               | ${false}
    ${'source is null'}                                         | ${null}                                                                                                                                                                         | ${false}
    ${'source is undefined'}                                    | ${undefined}                                                                                                                                                                    | ${false}
  `('$scenario', ({ source, expected }) => {
    it(`returns ${expected}`, () => {
      expect(validateMutationData(source)).toBe(expected);
    });
  });
});
