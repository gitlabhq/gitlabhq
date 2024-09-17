import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerHeaderActions from '~/ci/runner/components/runner_header_actions.vue';

import RunnerPauseButton from '~/ci/runner/components/runner_pause_button.vue';
import RunnerDeleteButton from '~/ci/runner/components/runner_delete_button.vue';
import RunnerEditButton from '~/ci/runner/components/runner_edit_button.vue';

import RunnerEditDisclosureDropdownItem from '~/ci/runner/components/runner_edit_disclosure_dropdown_item.vue';
import RunnerPauseDisclosureDropdownItem from '~/ci/runner/components/runner_pause_disclosure_dropdown_item.vue';
import RunnerDeleteDisclosureDropdownItem from '~/ci/runner/components/runner_delete_disclosure_dropdown_item.vue';

import { runnerData } from '../mock_data';

const mockRunner = runnerData.data.runner;
const mockRunnerEditPath = '/edit';

describe('RunnerHeaderActions', () => {
  let wrapper;

  const findRunnerEditButton = () => wrapper.findComponent(RunnerEditButton);
  const findRunnerPauseButton = () => wrapper.findComponent(RunnerPauseButton);
  const findRunnerDeleteButton = () => wrapper.findComponent(RunnerDeleteButton);

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findEditItem = () => findDropdown().findComponent(RunnerEditDisclosureDropdownItem);
  const findPauseItem = () => findDropdown().findComponent(RunnerPauseDisclosureDropdownItem);
  const findDeleteItem = () => findDropdown().findComponent(RunnerDeleteDisclosureDropdownItem);

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
    expect(findRunnerEditButton().exists()).toBe(true);
    expect(findRunnerPauseButton().exists()).toBe(true);
    expect(findRunnerDeleteButton().exists()).toBe(true);

    // visible on small screens
    expect(findDropdown().exists()).toBe(true);
    expect(findEditItem().exists()).toBe(true);
    expect(findPauseItem().exists()).toBe(true);
    expect(findDeleteItem().exists()).toBe(true);
  });

  it('renders disclosure dropdown with no caret and accesible text', () => {
    expect(findDropdown().props()).toMatchObject({
      icon: 'ellipsis_v',
      toggleText: 'Runner actions',
      textSrOnly: true,
      category: 'tertiary',
      noCaret: true,
    });
  });

  it.each([findRunnerEditButton, findEditItem])('edit path is set (%p)', (find) => {
    expect(find().props('href')).toEqual(mockRunnerEditPath);
  });

  it.each([findRunnerDeleteButton, findDeleteItem])('delete is emitted (%p)', (find) => {
    const deleteEvent = { message: 'Deleted!' };

    find().vm.$emit('deleted', deleteEvent);

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
      expect(findRunnerDeleteButton().exists()).toBe(false);
      expect(findDeleteItem().exists()).toBe(false);
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
