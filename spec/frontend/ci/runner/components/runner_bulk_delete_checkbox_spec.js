import Vue from 'vue';
import { GlFormCheckbox } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerBulkDeleteCheckbox from '~/ci/runner/components/runner_bulk_delete_checkbox.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createLocalState } from '~/ci/runner/graphql/list/local_state';

Vue.use(VueApollo);

const makeRunner = (id, deleteRunner = true) => ({
  id,
  userPermissions: { deleteRunner },
});

// Multi-select checkbox possible states:
const stateToAttrs = {
  unchecked: { disabled: undefined, checked: undefined, indeterminate: undefined },
  checked: { disabled: undefined, checked: 'true', indeterminate: undefined },
  indeterminate: { disabled: undefined, checked: undefined, indeterminate: 'true' },
  disabled: { disabled: 'true', checked: undefined, indeterminate: undefined },
};

describe('RunnerBulkDeleteCheckbox', () => {
  let wrapper;
  let mockState;
  let mockCheckedRunnerIds;

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  const expectCheckboxToBe = (state) => {
    const expected = stateToAttrs[state];
    expect(findCheckbox().attributes().disabled).toBe(expected.disabled);
    expect(findCheckbox().attributes('checked')).toBe(expected.checked);
    expect(findCheckbox().attributes('indeterminate')).toBe(expected.indeterminate);
  };

  const createComponent = ({ runners = [] } = {}) => {
    const { cacheConfig, localMutations } = mockState;
    const apolloProvider = createMockApollo(undefined, undefined, cacheConfig);

    wrapper = shallowMountExtended(RunnerBulkDeleteCheckbox, {
      apolloProvider,
      provide: {
        localMutations,
      },
      propsData: {
        runners,
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

  describe('when all runners can be deleted', () => {
    const mockIds = ['1', '2', '3'];
    const mockIdAnotherPage = '4';
    const mockRunners = mockIds.map((id) => makeRunner(id));

    it.each`
      case                         | checkedRunnerIds                   | state
      ${'no runners'}              | ${[]}                              | ${'unchecked'}
      ${'no runners in this page'} | ${[mockIdAnotherPage]}             | ${'unchecked'}
      ${'all runners'}             | ${mockIds}                         | ${'checked'}
      ${'some runners'}            | ${[mockIds[0]]}                    | ${'indeterminate'}
      ${'all plus other runners'}  | ${[...mockIds, mockIdAnotherPage]} | ${'checked'}
    `('if $case are checked, checkbox is $state', ({ checkedRunnerIds, state }) => {
      mockCheckedRunnerIds = checkedRunnerIds;

      createComponent({ runners: mockRunners });
      expectCheckboxToBe(state);
    });
  });

  describe('when some runners cannot be deleted', () => {
    it('all allowed runners are selected, checkbox is checked', () => {
      mockCheckedRunnerIds = ['a', 'b', 'c'];
      createComponent({
        runners: [makeRunner('a'), makeRunner('b'), makeRunner('c', false)],
      });

      expectCheckboxToBe('checked');
    });

    it('some allowed runners are selected, checkbox is indeterminate', () => {
      mockCheckedRunnerIds = ['a', 'b'];
      createComponent({
        runners: [makeRunner('a'), makeRunner('b'), makeRunner('c')],
      });

      expectCheckboxToBe('indeterminate');
    });

    it('no allowed runners are selected, checkbox is disabled', () => {
      mockCheckedRunnerIds = ['a', 'b'];
      createComponent({
        runners: [makeRunner('a', false), makeRunner('b', false)],
      });

      expectCheckboxToBe('disabled');
    });
  });

  describe('When user selects', () => {
    const mockRunners = [makeRunner('1'), makeRunner('2')];

    beforeEach(() => {
      mockCheckedRunnerIds = ['1', '2'];
      createComponent({ runners: mockRunners });
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
      createComponent();
    });

    it('is disabled', () => {
      expectCheckboxToBe('disabled');
    });
  });
});
