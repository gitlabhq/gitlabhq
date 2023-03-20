import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ExperimentComponent from '~/experimentation/components/gitlab_experiment.vue';

const defaultProps = { name: 'experiment_name' };
const defaultSlots = {
  candidate: `<p>Candidate</p>`,
  control: `<p>Control</p>`,
};

describe('ExperimentComponent', () => {
  let wrapper;

  const createComponent = (propsData = defaultProps, slots = defaultSlots) => {
    wrapper = extendedWrapper(shallowMount(ExperimentComponent, { propsData, slots }));
  };

  const mockVariant = (expectedVariant) => {
    window.gon = { experiment: { experiment_name: { variant: expectedVariant } } };
  };

  describe('when variant and experiment is set', () => {
    it('renders control when it is the active variant', () => {
      mockVariant('control');

      createComponent();

      expect(wrapper.text()).toBe('Control');
    });

    it('renders candidate when it is the active variant', () => {
      mockVariant('candidate');

      createComponent();

      expect(wrapper.text()).toBe('Candidate');
    });
  });

  describe('when variant or experiment is not set', () => {
    it('renders the control slot when no variant is defined', () => {
      mockVariant(undefined);

      createComponent();

      expect(wrapper.text()).toBe('Control');
    });

    it('renders nothing when behavior is not set for variant', () => {
      mockVariant('non-existing-variant');

      createComponent(defaultProps, { control: `<p>First</p>`, other: `<p>Other</p>` });

      expect(wrapper.text()).toBe('');
    });

    it('renders nothing when there are no slots', () => {
      mockVariant('control');

      createComponent(defaultProps, {});

      expect(wrapper.text()).toBe('');
    });
  });
});
