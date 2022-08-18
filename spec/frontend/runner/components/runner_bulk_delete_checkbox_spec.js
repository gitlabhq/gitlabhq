import Vue from 'vue';
import { GlFormCheckbox } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerBulkDeleteCheckbox from '~/runner/components/runner_bulk_delete_checkbox.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createLocalState } from '~/runner/graphql/list/local_state';
import { allRunnersData } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/flash');

describe('RunnerBulkDeleteCheckbox', () => {
  let wrapper;
  let mockState;
  let mockCheckedRunnerIds;

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  const mockRunners = allRunnersData.data.runners.nodes;
  const mockIds = allRunnersData.data.runners.nodes.map(({ id }) => id);
  const mockId = mockIds[0];
  const mockIdAnotherPage = 'RUNNER_IN_ANOTHER_PAGE_ID';

  const createComponent = ({ props = {} } = {}) => {
    const { cacheConfig, localMutations } = mockState;
    const apolloProvider = createMockApollo(undefined, undefined, cacheConfig);

    wrapper = shallowMountExtended(RunnerBulkDeleteCheckbox, {
      apolloProvider,
      provide: {
        localMutations,
      },
      propsData: {
        runners: mockRunners,
        ...props,
      },
    });
  };

  beforeEach(() => {
    mockState = createLocalState();

    jest
      .spyOn(mockState.cacheConfig.typePolicies.Query.fields, 'checkedRunnerIds')
      .mockImplementation(() => mockCheckedRunnerIds);

    jest.spyOn(mockState.localMutations, 'setRunnersChecked');
  });

  describe.each`
    case                         | is                 | checkedRunnerIds                   | disabled     | checked      | indeterminate
    ${'no runners'}              | ${'unchecked'}     | ${[]}                              | ${undefined} | ${undefined} | ${undefined}
    ${'no runners in this page'} | ${'unchecked'}     | ${[mockIdAnotherPage]}             | ${undefined} | ${undefined} | ${undefined}
    ${'all runners'}             | ${'checked'}       | ${mockIds}                         | ${undefined} | ${'true'}    | ${undefined}
    ${'some runners'}            | ${'indeterminate'} | ${[mockId]}                        | ${undefined} | ${undefined} | ${'true'}
    ${'all plus other runners'}  | ${'checked'}       | ${[...mockIds, mockIdAnotherPage]} | ${undefined} | ${'true'}    | ${undefined}
  `('When $case are checked', ({ is, checkedRunnerIds, disabled, checked, indeterminate }) => {
    beforeEach(async () => {
      mockCheckedRunnerIds = checkedRunnerIds;

      createComponent();
    });

    it(`is ${is}`, () => {
      expect(findCheckbox().attributes('disabled')).toBe(disabled);
      expect(findCheckbox().attributes('checked')).toBe(checked);
      expect(findCheckbox().attributes('indeterminate')).toBe(indeterminate);
    });
  });

  describe('When user selects', () => {
    beforeEach(() => {
      mockCheckedRunnerIds = mockIds;
      createComponent();
    });

    it.each([[true], [false]])('sets checked to %s', (checked) => {
      findCheckbox().vm.$emit('change', checked);

      expect(mockState.localMutations.setRunnersChecked).toHaveBeenCalledTimes(1);
      expect(mockState.localMutations.setRunnersChecked).toHaveBeenCalledWith({
        isChecked: checked,
        runners: mockRunners,
      });
    });
  });

  describe('When runners are loading', () => {
    beforeEach(() => {
      createComponent({ props: { runners: [] } });
    });

    it(`is disabled`, () => {
      expect(findCheckbox().attributes('disabled')).toBe('true');
      expect(findCheckbox().attributes('checked')).toBe(undefined);
      expect(findCheckbox().attributes('indeterminate')).toBe(undefined);
    });
  });
});
