import { GlAvatar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerDetailGroups from '~/runner/components/runner_detail_groups.vue';

import { runnerData, runnerWithGroupData } from '../mock_data';

const mockInstanceRunner = runnerData.data.runner;
const mockGroupRunner = runnerWithGroupData.data.runner;
const mockGroup = mockGroupRunner.groups.nodes[0];

describe('RunnerDetailGroups', () => {
  let wrapper;

  const findHeading = () => wrapper.find('h3');
  const findGroupAvatar = () => wrapper.findByTestId('group-avatar');

  const createComponent = ({ runner = mockGroupRunner, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerDetailGroups, {
      propsData: {
        runner,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Shows a heading', () => {
    createComponent();

    expect(findHeading().text()).toBe('Assigned Group');
  });

  describe('When there is group runner', () => {
    beforeEach(() => {
      createComponent();
    });

    it('Shows a group avatar', () => {
      const avatar = findGroupAvatar();

      expect(avatar.attributes('href')).toBe(mockGroup.webUrl);
      expect(avatar.findComponent(GlAvatar).props()).toMatchObject({
        alt: mockGroup.name,
        entityName: mockGroup.name,
        src: mockGroup.avatarUrl,
        shape: 'rect',
        size: 48,
      });
    });

    it('Shows a group link', () => {
      const groupFullName = wrapper.findByText(mockGroup.fullName);

      expect(groupFullName.attributes('href')).toBe(mockGroup.webUrl);
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
