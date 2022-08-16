import { mountExtended } from 'helpers/vue_test_utils_helper';
import CiVariableTable from '~/ci_variable_list/components/ci_variable_table.vue';
import { projectString } from '~/ci_variable_list/constants';
import { mockVariables } from '../mocks';

describe('Ci variable table', () => {
  let wrapper;

  const defaultProps = {
    isLoading: false,
    variables: mockVariables(projectString),
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(CiVariableTable, {
      attachTo: document.body,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findRevealButton = () => wrapper.findByText('Reveal values');
  const findAddButton = () => wrapper.findByLabelText('Add');
  const findEditButton = () => wrapper.findByLabelText('Edit');
  const findEmptyVariablesPlaceholder = () => wrapper.findByText('There are no variables yet.');
  const findHiddenValues = () => wrapper.findAll('[data-testid="hiddenValue"]');
  const findRevealedValues = () => wrapper.findAll('[data-testid="revealedValue"]');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('When table is empty', () => {
    beforeEach(() => {
      createComponent({ props: { variables: [] } });
    });

    it('displays empty message', () => {
      expect(findEmptyVariablesPlaceholder().exists()).toBe(true);
    });

    it('hides the reveal button', () => {
      expect(findRevealButton().exists()).toBe(false);
    });
  });

  describe('When table has variables', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not display the empty message', () => {
      expect(findEmptyVariablesPlaceholder().exists()).toBe(false);
    });

    it('displays the reveal button', () => {
      expect(findRevealButton().exists()).toBe(true);
    });

    it('displays the correct amount of variables', async () => {
      expect(wrapper.findAll('.js-ci-variable-row')).toHaveLength(defaultProps.variables.length);
    });
  });

  describe('Table click actions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('reveals secret values when button is clicked', async () => {
      expect(findHiddenValues()).toHaveLength(defaultProps.variables.length);
      expect(findRevealedValues()).toHaveLength(0);

      await findRevealButton().trigger('click');

      expect(findHiddenValues()).toHaveLength(0);
      expect(findRevealedValues()).toHaveLength(defaultProps.variables.length);
    });

    it('dispatches `setSelectedVariable` with correct variable to edit', async () => {
      await findEditButton().trigger('click');

      expect(wrapper.emitted('set-selected-variable')).toEqual([[defaultProps.variables[0]]]);
    });

    it('dispatches `setSelectedVariable` with no variable when adding a new one', async () => {
      await findAddButton().trigger('click');

      expect(wrapper.emitted('set-selected-variable')).toEqual([[null]]);
    });
  });
});
