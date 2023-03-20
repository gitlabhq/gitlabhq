import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerGroups from '~/ci/runner/components/runner_groups.vue';
import RunnerAssignedItem from '~/ci/runner/components/runner_assigned_item.vue';

import { runnerData, runnerWithGroupData } from '../mock_data';

const mockInstanceRunner = runnerData.data.runner;
const mockGroupRunner = runnerWithGroupData.data.runner;
const mockGroup = mockGroupRunner.groups.nodes[0];

describe('RunnerGroups', () => {
  let wrapper;

  const findHeading = () => wrapper.find('h3');
  const findRunnerAssignedItems = () => wrapper.findAllComponents(RunnerAssignedItem);

  const createComponent = ({ runner = mockGroupRunner, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerGroups, {
      propsData: {
        runner,
      },
    });
  };

  it('Shows a heading', () => {
    createComponent();

    expect(findHeading().text()).toBe('Assigned Group');
  });

  describe('When there is a group runner', () => {
    beforeEach(() => {
      createComponent();
    });

    it('Shows a project', () => {
      createComponent();

      const item = findRunnerAssignedItems().at(0);
      const { webUrl, name, fullName, avatarUrl } = mockGroup;

      expect(item.props()).toMatchObject({
        href: webUrl,
        name,
        fullName,
        avatarUrl,
      });
    });
  });

  describe('When there are no groups', () => {
    beforeEach(() => {
      createComponent({
        runner: mockInstanceRunner,
      });
    });

    it('Shows a "None" label', () => {
      expect(wrapper.findByText('None').exists()).toBe(true);
    });
  });
});
