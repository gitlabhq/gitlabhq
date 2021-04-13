import { GlAvatarLabeled } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SidebarParticipant from '~/sidebar/components/assignees/sidebar_participant.vue';

const user = {
  name: 'John Doe',
  username: 'johndoe',
  webUrl: '/link',
  avatarUrl: '/avatar',
};

describe('Sidebar participant component', () => {
  let wrapper;

  const findAvatar = () => wrapper.findComponent(GlAvatarLabeled);

  const createComponent = (status = null) => {
    wrapper = shallowMount(SidebarParticipant, {
      propsData: {
        user: {
          ...user,
          status,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('when user is not busy', () => {
    createComponent();

    expect(findAvatar().props('label')).toBe(user.name);
  });

  it('when user is busy', () => {
    createComponent({ availability: 'BUSY' });

    expect(findAvatar().props('label')).toBe(`${user.name} (Busy)`);
  });
});
