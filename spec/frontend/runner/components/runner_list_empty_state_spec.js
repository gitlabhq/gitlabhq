import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';

import RunnerListEmptyState from '~/runner/components/runner_list_empty_state.vue';

const mockSvgPath = 'mock-svg-path.svg';
const mockFilteredSvgPath = 'mock-filtered-svg-path.svg';

describe('RunnerListEmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLink = () => wrapper.findComponent(GlLink);
  const findRunnerInstructionsModal = () => wrapper.findComponent(RunnerInstructionsModal);

  const createComponent = ({ props, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerListEmptyState, {
      propsData: {
        svgPath: mockSvgPath,
        filteredSvgPath: mockFilteredSvgPath,
        ...props,
      },
      directives: {
        GlModal: createMockDirective(),
      },
      stubs: {
        GlEmptyState,
        GlSprintf,
        GlLink,
      },
    });
  };

  describe('when search is not filtered', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders an illustration', () => {
      expect(findEmptyState().props('svgPath')).toBe(mockSvgPath);
    });

    it('displays "no results" text', () => {
      const title = s__('Runners|Get started with runners');
      const desc = s__(
        'Runners|Runners are the agents that run your CI/CD jobs. Follow the %{linkStart}installation and registration instructions%{linkEnd} to set up a runner.',
      );

      expect(findEmptyState().text()).toMatchInterpolatedText(`${title} ${desc}`);
    });

    it('opens a runner registration instructions modal with a link', () => {
      const { value } = getBinding(findLink().element, 'gl-modal');

      expect(findRunnerInstructionsModal().props('modalId')).toEqual(value);
    });
  });

  describe('when search is filtered', () => {
    beforeEach(() => {
      createComponent({ props: { isSearchFiltered: true } });
    });

    it('renders a "filtered search" illustration', () => {
      expect(findEmptyState().props('svgPath')).toBe(mockFilteredSvgPath);
    });

    it('displays "no filtered results" text', () => {
      expect(findEmptyState().text()).toContain(s__('Runners|No results found'));
      expect(findEmptyState().text()).toContain(s__('Runners|Edit your search and try again'));
    });
  });
});
