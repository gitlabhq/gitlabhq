import { GlAvatar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerAssignedItem from '~/runner/components/runner_assigned_item.vue';

const mockHref = '/group/project';
const mockName = 'Project';
const mockFullName = 'Group / Project';
const mockAvatarUrl = '/avatar.png';

describe('RunnerAssignedItem', () => {
  let wrapper;

  const findAvatar = () => wrapper.findByTestId('item-avatar');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(RunnerAssignedItem, {
      propsData: {
        href: mockHref,
        name: mockName,
        fullName: mockFullName,
        avatarUrl: mockAvatarUrl,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Shows an avatar', () => {
    const avatar = findAvatar();

    expect(avatar.attributes('href')).toBe(mockHref);
    expect(avatar.findComponent(GlAvatar).props()).toMatchObject({
      alt: mockName,
      entityName: mockName,
      src: mockAvatarUrl,
      shape: 'rect',
      size: 48,
    });
  });

  it('Shows an item link', () => {
    const groupFullName = wrapper.findByText(mockFullName);

    expect(groupFullName.attributes('href')).toBe(mockHref);
  });
});
