import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerActionsCell from '~/ci/runner/components/cells/runner_actions_cell.vue';
import RunnerPauseButton from '~/ci/runner/components/runner_pause_button.vue';
import RunnerEditButton from '~/ci/runner/components/runner_edit_button.vue';
import RunnerDeleteButton from '~/ci/runner/components/runner_delete_button.vue';
import { allRunnersData } from '../../mock_data';

const mockRunner = allRunnersData.data.runners.nodes[0];

describe('RunnerActionsCell', () => {
  let wrapper;

  const findEditBtn = () => wrapper.findComponent(RunnerEditButton);
  const findRunnerPauseBtn = () => wrapper.findComponent(RunnerPauseButton);
  const findDeleteBtn = () => wrapper.findComponent(RunnerDeleteButton);

  const createComponent = ({ runner = {}, ...props } = {}) => {
    wrapper = shallowMountExtended(RunnerActionsCell, {
      propsData: {
        editUrl: mockRunner.editAdminUrl,
        runner: {
          id: mockRunner.id,
          shortSha: mockRunner.shortSha,
          editAdminUrl: mockRunner.editAdminUrl,
          userPermissions: mockRunner.userPermissions,
          ...runner,
        },
        ...props,
      },
    });
  };

  describe('Edit Action', () => {
    it('Displays the runner edit link with the correct href', () => {
      createComponent();

      expect(findEditBtn().attributes('href')).toBe(mockRunner.editAdminUrl);
    });

    it('Does not render the runner edit link when user cannot update', () => {
      createComponent({
        runner: {
          userPermissions: {
            ...mockRunner.userPermissions,
            updateRunner: false,
          },
        },
      });

      expect(findEditBtn().exists()).toBe(false);
    });

    it('Does not render the runner edit link when editUrl is not provided', () => {
      createComponent({
        editUrl: null,
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
        runner: {
          userPermissions: {
            ...mockRunner.userPermissions,
            updateRunner: false,
          },
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

    it('Passes runner data to delete button', () => {
      createComponent({
        runner: mockRunner,
      });

      expect(findDeleteBtn().props('runner')).toEqual(mockRunner);
    });

    it('Emits toggledPaused events', () => {
      createComponent();

      expect(wrapper.emitted('toggledPaused')).toBe(undefined);

      findRunnerPauseBtn().vm.$emit('toggledPaused');

      expect(wrapper.emitted('toggledPaused')).toHaveLength(1);
    });

    it('Emits delete events', () => {
      const value = { name: 'Runner' };

      createComponent();

      expect(wrapper.emitted('deleted')).toBe(undefined);

      findDeleteBtn().vm.$emit('deleted', value);

      expect(wrapper.emitted('deleted')).toEqual([[value]]);
    });

    it('Does not render the runner delete button when user cannot delete', () => {
      createComponent({
        runner: {
          userPermissions: {
            ...mockRunner.userPermissions,
            deleteRunner: false,
          },
        },
      });

      expect(findDeleteBtn().exists()).toBe(false);
    });
  });
});
