import { GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserAvatarPresenter from '~/glql/components/presenters/user_avatar.vue';
import { MOCK_ANALYTICS_USER } from '../../mock_data';

describe('UserAvatarPresenter', () => {
  let wrapper;

  const createWrapper = ({ data }) => {
    wrapper = shallowMountExtended(UserAvatarPresenter, {
      propsData: { data },
    });
  };

  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);

  it('renders a linked avatar with label and sub-label', () => {
    createWrapper({ data: MOCK_ANALYTICS_USER });

    expect(findAvatarLink().attributes('href')).toBe('https://gitlab.com/foobar');

    const labeled = findAvatarLabeled();
    expect(labeled.props('label')).toBe('Foo Bar');
    expect(labeled.props('subLabel')).toBe('@foobar');
    expect(labeled.props('src')).toBe(
      'https://gitlab.com/uploads/-/system/user/avatar/1/avatar.png',
    );
    expect(labeled.props('size')).toBe(32);
  });

  it('parses numeric entity ID from a numeric id', () => {
    createWrapper({ data: MOCK_ANALYTICS_USER });

    expect(findAvatarLabeled().props('entityId')).toBe(1);
  });

  it('parses numeric entity ID from a GID string', () => {
    createWrapper({ data: { ...MOCK_ANALYTICS_USER, id: 'gid://gitlab/User/19' } });

    expect(findAvatarLabeled().props('entityId')).toBe(19);
  });
});
