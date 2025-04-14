import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerGroups from '~/ci/runner/components/runner_groups.vue';
import RunnerAssignedItem from '~/ci/runner/components/runner_assigned_item.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

import { runnerData, runnerWithGroupData } from '../mock_data';

const mockInstanceRunner = runnerData.data.runner;
const mockGroupRunner = runnerWithGroupData.data.runner;
const mockGroup = mockGroupRunner.groups.nodes[0];

describe('RunnerGroups', () => {
  let wrapper;

  const findHeading = () => wrapper.findByTestId('crud-title');
  const findRunnerAssignedItems = () => wrapper.findAllComponents(RunnerAssignedItem);

  const createComponent = ({ runner = mockGroupRunner, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerGroups, {
      propsData: {
        runner,
      },
      stubs: {
        CrudComponent,
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

      expect(wrapper.findByTestId('runner-groups').exists()).toBe(true);

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

    it('Hides component', () => {
      expect(wrapper.findByTestId('runner-groups').exists()).toBe(false);
    });
  });
});
