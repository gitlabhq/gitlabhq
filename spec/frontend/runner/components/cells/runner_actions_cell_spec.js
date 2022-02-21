import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerActionsCell from '~/runner/components/cells/runner_actions_cell.vue';
import RunnerPauseButton from '~/runner/components/runner_pause_button.vue';
import RunnerEditButton from '~/runner/components/runner_edit_button.vue';
import RunnerDeleteButton from '~/runner/components/runner_delete_button.vue';
import { runnersData } from '../../mock_data';

const mockRunner = runnersData.data.runners.nodes[0];

describe('RunnerActionsCell', () => {
  let wrapper;

  const findEditBtn = () => wrapper.findComponent(RunnerEditButton);
  const findRunnerPauseBtn = () => wrapper.findComponent(RunnerPauseButton);
  const findDeleteBtn = () => wrapper.findComponent(RunnerDeleteButton);

  const createComponent = (runner = {}, options) => {
    wrapper = shallowMountExtended(RunnerActionsCell, {
      propsData: {
        runner: {
          id: mockRunner.id,
          shortSha: mockRunner.shortSha,
          editAdminUrl: mockRunner.editAdminUrl,
          userPermissions: mockRunner.userPermissions,
          ...runner,
        },
      },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Edit Action', () => {
    it('Displays the runner edit link with the correct href', () => {
      createComponent();

      expect(findEditBtn().attributes('href')).toBe(mockRunner.editAdminUrl);
    });

    it('Does not render the runner edit link when user cannot update', () => {
      createComponent({
        userPermissions: {
          ...mockRunner.userPermissions,
          updateRunner: false,
        },
      });

      expect(findEditBtn().exists()).toBe(false);
    });

    it('Does not render the runner edit link when editAdminUrl is not provided', () => {
      createComponent({
        editAdminUrl: null,
      });

      expect(findEditBtn().exists()).toBe(false);
    });
  });

  describe('Pause action', () => {
    it('Renders a compact pause button', () => {
      createComponent();

      expect(findRunnerPauseBtn().props('compact')).toBe(true);
    });

    it('Does not render the runner pause button when user cannot update', () => {
      createComponent({
        userPermissions: {
          ...mockRunner.userPermissions,
          updateRunner: false,
        },
      });

      expect(findRunnerPauseBtn().exists()).toBe(false);
    });
  });

  describe('Delete action', () => {
    it('Renders a compact delete button', () => {
      createComponent();

      expect(findDeleteBtn().props('compact')).toBe(true);
    });

    it('Does not render the runner delete button when user cannot delete', () => {
      createComponent({
        userPermissions: {
          ...mockRunner.userPermissions,
          deleteRunner: false,
        },
      });

      expect(findDeleteBtn().exists()).toBe(false);
    });
  });
});
