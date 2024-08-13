import { GlAvatar, GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerAssignedItem from '~/ci/runner/components/runner_assigned_item.vue';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

const mockHref = '/group/project';
const mockName = 'Project';
const mockDescription = 'Project description';
const mockFullName = 'Group / Project';
const mockAvatarUrl = '/avatar.png';

describe('RunnerAssignedItem', () => {
  let wrapper;

  const findAvatar = () => wrapper.findByTestId('item-avatar');
  const findBadge = () => wrapper.findComponent(GlBadge);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(RunnerAssignedItem, {
      propsData: {
        href: mockHref,
        name: mockName,
        fullName: mockFullName,
        avatarUrl: mockAvatarUrl,
        description: mockDescription,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('Shows an avatar', () => {
    const avatar = findAvatar();

    expect(avatar.attributes('href')).toBe(mockHref);
    expect(avatar.findComponent(GlAvatar).props()).toMatchObject({
      alt: mockName,
      entityName: mockName,
      src: mockAvatarUrl,
      shape: AVATAR_SHAPE_OPTION_RECT,
      size: 48,
    });
  });

  it('Shows an item link', () => {
    const groupFullName = wrapper.findByText(mockFullName);

    expect(groupFullName.attributes('href')).toBe(mockHref);
  });

  it('Shows description', () => {
    expect(wrapper.text()).toContain(mockDescription);
  });

  it('Shows owner badge', () => {
    createComponent({ props: { isOwner: true } });

    expect(findBadge().text()).toBe('Owner');
  });
});
