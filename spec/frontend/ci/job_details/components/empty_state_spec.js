import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EmptyState from '~/ci/job_details/components/empty_state.vue';

describe('Empty State', () => {
  let wrapper;

  const defaultProps = {
    illustrationPath: 'illustrations/empty-state/empty-job-pending-md.svg',
    title: 'This job has not started yet',
  };

  const createWrapper = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(EmptyState, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const content = 'This job is in pending state and is waiting to be picked by a runner';

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findEmptyStateImage = () => findEmptyState().props('svgPath');
  const findTitle = () => findEmptyState().props('title');
  const findContent = () => wrapper.findByTestId('job-empty-state-content');
  const findAction = () => wrapper.findByTestId('job-empty-state-action');

  describe('renders image and title', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders empty state image', () => {
      expect(findEmptyStateImage()).toBe(defaultProps.illustrationPath);
    });

    it('renders provided title', () => {
      expect(findTitle()).toBe(defaultProps.title);
    });
  });

  describe('with content', () => {
    beforeEach(() => {
      createWrapper({ props: { content } });
    });

    it('renders content', () => {
      expect(findContent().text().trim()).toBe(content);
    });
  });

  describe('without content', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not render content', () => {
      expect(findContent().exists()).toBe(false);
    });
  });

  describe('with action', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          action: {
            path: 'runner',
            button_title: 'Check runner',
            method: 'post',
          },
        },
      });
    });

    it('renders action', () => {
      expect(findAction().attributes('href')).toBe('runner');
    });
  });

  describe('without action', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          action: null,
        },
      });
    });

    it('does not render action', () => {
      expect(findAction().exists()).toBe(false);
    });
  });
});
