import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerCell from '~/pages/admin/jobs/components/table/cells/runner_cell.vue';
import { RUNNER_EMPTY_TEXT } from '~/pages/admin/jobs/components/constants';
import { allRunnersData } from '../../../../../../ci/runner/mock_data';

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
});
