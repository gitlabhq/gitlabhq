import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import RunnerHeaderActions from '~/ci/runner/components/runner_header_actions.vue';

import RunnerPauseButton from '~/ci/runner/components/runner_pause_button.vue';
import RunnerEditButton from '~/ci/runner/components/runner_edit_button.vue';

import RunnerEditDisclosureDropdownItem from '~/ci/runner/components/runner_edit_disclosure_dropdown_item.vue';
import RunnerPauseDisclosureDropdownItem from '~/ci/runner/components/runner_pause_disclosure_dropdown_item.vue';
import RunnerDeleteDisclosureDropdownItem from '~/ci/runner/components/runner_delete_disclosure_dropdown_item.vue';

import { runnerData } from '../mock_data';

const mockRunner = runnerData.data.runner;
const mockRunnerEditPath = '/edit';

describe('RunnerHeaderActions', () => {
  let wrapper;

  const findExpandedActions = () => wrapper.findByTestId('expanded-runner-actions');
  const findRunnerEditButton = () => findExpandedActions().findComponent(RunnerEditButton);
  const findRunnerPauseButton = () => findExpandedActions().findComponent(RunnerPauseButton);
  const findExpandedDropdown = () => findExpandedActions().findComponent(GlDisclosureDropdown);
  const findExpandedRunnerDeleteItem = () =>
    findExpandedActions().findComponent(RunnerDeleteDisclosureDropdownItem);
  const findExpandedDropdownTooltip = () =>
    getBinding(findExpandedDropdown().element, 'gl-tooltip').value || '';

  const findCompactDropdown = () => wrapper.findByTestId('compact-runner-actions');
  const findCompactDropdownTooltip = () =>
    getBinding(findCompactDropdown().element, 'gl-tooltip').value || '';
  const findEditItem = () => findCompactDropdown().findComponent(RunnerEditDisclosureDropdownItem);
  const findPauseItem = () =>
    findCompactDropdown().findComponent(RunnerPauseDisclosureDropdownItem);
  const findDeleteItem = () =>
    findCompactDropdown().findComponent(RunnerDeleteDisclosureDropdownItem);

  const createComponent = ({ props = {}, options = {}, mountFn = shallowMountExtended } = {}) => {
    const { runner, ...propsData } = props;

    wrapper = mountFn(RunnerHeaderActions, {
      propsData: {
        runner: {
          ...mockRunner,
          ...runner,
        },
        editPath: mockRunnerEditPath,
        ...propsData,
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders all elements', () => {
    // visible on md and up screens
    expect(findExpandedDropdown().exists()).toBe(true);
    expect(findRunnerEditButton().exists()).toBe(true);
    expect(findRunnerPauseButton().exists()).toBe(true);
    expect(findExpandedRunnerDeleteItem().exists()).toBe(true);

    // visible on small screens
    expect(findCompactDropdown().exists()).toBe(true);
    expect(findEditItem().exists()).toBe(true);
    expect(findPauseItem().exists()).toBe(true);
    expect(findDeleteItem().exists()).toBe(true);
  });

  describe('More actions menu', () => {
    beforeEach(() => {
      createComponent({
        options: {
          directives: {
            GlTooltip: createMockDirective('gl-tooltip'),
          },
          stubs: { GlDisclosureDropdown },
        },
      });
    });

    it('renders disclosure dropdown with correct props', () => {
      const props = {
        icon: 'ellipsis_v',
        textSrOnly: true,
        category: 'tertiary',
        noCaret: true,
        toggleText: 'Runner actions',
      };

      expect(findExpandedDropdown().props()).toMatchObject({
        ...props,
      });

      expect(findCompactDropdown().props()).toMatchObject({
        ...props,
      });
    });

    it('renders the tooltip text', () => {
      expect(findExpandedDropdownTooltip()).toBe('More actions');
      expect(findCompactDropdownTooltip()).toBe('More actions');
    });

    it('hides tooltip text when @shown is emitted', async () => {
      await findExpandedDropdown().vm.$emit('shown');

      expect(findExpandedDropdownTooltip()).toBe('');
      expect(findCompactDropdownTooltip()).toBe('');
    });
  });

  it.each([findRunnerEditButton, findEditItem])('edit path is set (%p)', (find) => {
    expect(find().props('href')).toEqual(mockRunnerEditPath);
  });

  it('delete is emitted', () => {
    const deleteEvent = { message: 'Deleted!' };

    findDeleteItem().vm.$emit('deleted', deleteEvent);

    expect(wrapper.emitted('deleted')).toEqual([[deleteEvent]]);
  });

  describe('when delete is disabled', () => {
    beforeEach(() => {
      createComponent({
        props: {
          runner: {
            userPermissions: {
              updateRunner: true,
              deleteRunner: false,
            },
          },
        },
      });
    });

    it('does not render delete actions', () => {
      expect(findDeleteItem().exists()).toBe(false);
      expect(findExpandedRunnerDeleteItem().exists()).toBe(false);
    });
  });

  describe('when update is disabled', () => {
    beforeEach(() => {
      createComponent({
        props: {
          runner: {
            userPermissions: {
              updateRunner: false,
              deleteRunner: true,
            },
          },
        },
      });
    });

    it('does not render delete actions', () => {
      expect(findRunnerEditButton().exists()).toBe(false);
      expect(findRunnerPauseButton().exists()).toBe(false);
      expect(findEditItem().exists()).toBe(false);
      expect(findPauseItem().exists()).toBe(false);
    });
  });

  describe('when no actions are enabled', () => {
    beforeEach(() => {
      createComponent({
        props: {
          runner: {
            userPermissions: {
              updateRunner: false,
              deleteRunner: false,
            },
          },
        },
      });
    });

    it('does not render actions', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });
  });
});
