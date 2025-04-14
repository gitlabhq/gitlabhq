import { GlAvatar, GlAvatarLink, GlBadge } from '@gitlab/ui';
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

  describe('Avatar', () => {
    const avatarProps = {
      alt: mockName,
      entityName: mockName,
      src: mockAvatarUrl,
      shape: AVATAR_SHAPE_OPTION_RECT,
      size: 32,
    };

    it('Shows an avatar as a link', () => {
      const avatarLink = wrapper.findAllComponents(GlAvatarLink).at(0);

      expect(avatarLink.attributes('href')).toBe(mockHref);
      expect(avatarLink.findComponent(GlAvatar).props()).toMatchObject(avatarProps);
    });

    describe('when href is undefined', () => {
      beforeEach(() => {
        createComponent({ props: { href: undefined } });
      });

      it('does not display avatar as a link', () => {
        expect(wrapper.findComponent(GlAvatarLink).exists()).toBe(false);
        expect(wrapper.findComponent(GlAvatar).props()).toMatchObject(avatarProps);
      });
    });
  });

  describe('Item', () => {
    it('Shows an item link', () => {
      const groupFullName = wrapper.findByText(mockFullName);

      expect(groupFullName.attributes('href')).toBe(mockHref);
    });

    describe('when href is undefined', () => {
      beforeEach(() => {
        createComponent({ props: { href: undefined } });
      });

      it('does not display item as a link', () => {
        expect(wrapper.findComponent(GlAvatarLink).exists()).toBe(false);

        expect(wrapper.findByText(mockFullName).exists()).toBe(true);
      });
    });
  });

  it('Shows description', () => {
    expect(wrapper.text()).toContain(mockDescription);
  });

  it('Shows owner badge', () => {
    createComponent({ props: { isOwner: true } });

    expect(findBadge().text()).toBe('Owner');
  });
});
