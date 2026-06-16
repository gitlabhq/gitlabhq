import { GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserLink from '~/analytics/analytics_dashboards/components/visualizations/data_table/user_link.vue';

const mockData = {
  name: 'Shikinami-Langley Asuka',
  avatarUrl:
    'https://www.gravatar.com/avatar/c4ab964b90c3049c47882b319d3c5cc0?s=80\u0026d=identicon',
  username: 'sachiel',
  webUrl: 'https://gitlab.com/fakeuser',
};

describe('UserLink', () => {
  let wrapper;

  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findLabeledAvatar = () => wrapper.findComponent(GlAvatarLabeled);

  describe('default', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(UserLink, {
        propsData: { ...mockData },
      });
    });

    it('renders the avatar link', () => {
      expect(findAvatarLink().attributes()).toEqual({
        href: 'https://gitlab.com/fakeuser',
        target: 'blank',
      });
    });

    it('renders the labeled avatar', () => {
      expect(findLabeledAvatar().attributes()).toMatchObject({
        label: 'Shikinami-Langley Asuka',
        sublabel: '@sachiel',
        alt: 'sachiel avatar',
        size: '32',
      });
    });
  });
});
