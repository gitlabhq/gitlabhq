import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerTypeIcon from '~/ci/runner/components/runner_type_icon.vue';
import RunnerCell from '~/ci/admin/jobs_table/components/cells/runner_cell.vue';
import { RUNNER_EMPTY_TEXT } from '~/ci/admin/jobs_table/constants';
import { allRunnersData } from 'jest/ci/runner/mock_data';

const mockRunner = allRunnersData.data.runners.nodes[0];

const mockJobWithRunner = {
  id: 'gid://gitlab/Ci::Build/2264',
  runner: mockRunner,
};

const mockJobWithoutRunner = {
  id: 'gid://gitlab/Ci::Build/2265',
};

describe('Runner Cell', () => {
  let wrapper;

  const findRunnerLink = () => wrapper.findComponent(GlLink);
  const findEmptyRunner = () => wrapper.find('[data-testid="empty-runner-text"]');

  const createComponent = (props = {}) => {
    wrapper = shallowMount(RunnerCell, {
      propsData: {
        ...props,
      },
    });
  };

  describe('Runner Link', () => {
    describe('Job with runner', () => {
      beforeEach(() => {
        createComponent({ job: mockJobWithRunner });
      });

      it('shows and links to the runner', () => {
        expect(findRunnerLink().exists()).toBe(true);
        expect(findRunnerLink().text()).toBe(mockRunner.description);
        expect(findRunnerLink().attributes('href')).toBe(mockRunner.adminUrl);
      });

      it('hides the empty runner text', () => {
        expect(findEmptyRunner().exists()).toBe(false);
      });
    });

    describe('Job without runner', () => {
      beforeEach(() => {
        createComponent({ job: mockJobWithoutRunner });
      });

      it('shows default `empty` text', () => {
        expect(findEmptyRunner().exists()).toBe(true);
        expect(findEmptyRunner().text()).toBe(RUNNER_EMPTY_TEXT);
      });

      it('hides the runner link', () => {
        expect(findRunnerLink().exists()).toBe(false);
      });
    });
  });

  describe('Runner Type Icon', () => {
    const findRunnerTypeIcon = () => wrapper.findComponent(RunnerTypeIcon);

    describe('Job with runner', () => {
      beforeEach(() => {
        createComponent({ job: mockJobWithRunner });
      });

      it('shows the runner type icon', () => {
        expect(findRunnerTypeIcon().exists()).toBe(true);
        expect(findRunnerTypeIcon().props('type')).toBe(mockJobWithRunner.runner.runnerType);
      });
    });

    describe('Job without runner', () => {
      beforeEach(() => {
        createComponent({ job: mockJobWithoutRunner });
      });

      it('does not show the runner type icon', () => {
        expect(findRunnerTypeIcon().exists()).toBe(false);
      });
    });
  });
});
