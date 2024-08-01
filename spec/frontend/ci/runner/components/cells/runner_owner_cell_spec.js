import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import RunnerOwnerCell from '~/ci/runner/components/cells/runner_owner_cell.vue';

import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/ci/runner/constants';

describe('RunnerOwnerCell', () => {
  let wrapper;

  const findLink = () => wrapper.findComponent(GlLink);
  const getLinkTooltip = () => getBinding(findLink().element, 'gl-tooltip').value;

  const createComponent = ({ runner } = {}) => {
    wrapper = shallowMount(RunnerOwnerCell, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        runner,
      },
    });
  };

  describe('When its an instance runner', () => {
    beforeEach(() => {
      createComponent({
        runner: {
          runnerType: INSTANCE_TYPE,
        },
      });
    });

    it('shows an administrator label', () => {
      expect(findLink().exists()).toBe(false);
      expect(wrapper.text()).toBe('Administrator');
    });
  });

  describe('When its a group runner', () => {
    const mockName = 'Group 2';
    const mockFullName = 'Group 1 / Group 2';
    const mockWebUrl = '/group-1/group-2';

    beforeEach(() => {
      createComponent({
        runner: {
          runnerType: GROUP_TYPE,
          groups: {
            nodes: [
              {
                name: mockName,
                fullName: mockFullName,
                webUrl: mockWebUrl,
              },
            ],
          },
        },
      });
    });

    it('Displays a group link', () => {
      expect(findLink().attributes('href')).toBe(mockWebUrl);
      expect(wrapper.text()).toBe(mockName);
      expect(getLinkTooltip()).toBe(mockFullName);
    });
  });

  describe('When its a project runner', () => {
    const mockName = 'Project 1';
    const mockNameWithNamespace = 'Group 1 / Project 1';
    const mockWebUrl = '/group-1/project-1';

    beforeEach(() => {
      createComponent({
        runner: {
          runnerType: PROJECT_TYPE,
          ownerProject: {
            name: mockName,
            nameWithNamespace: mockNameWithNamespace,
            webUrl: mockWebUrl,
          },
        },
      });
    });

    it('Displays a project link', () => {
      expect(findLink().attributes('href')).toBe(mockWebUrl);
      expect(wrapper.text()).toBe(mockName);
      expect(getLinkTooltip()).toBe(mockNameWithNamespace);
    });
  });

  describe('When its an empty runner', () => {
    beforeEach(() => {
      createComponent({
        runner: {},
      });
    });

    it('shows no label', () => {
      expect(wrapper.text()).toBe('');
    });
  });
});
