import { GlAvatar, GlAvatarLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeploymentTriggerer from '~/environments/environment_details/components/deployment_triggerer.vue';

describe('app/assets/javascripts/environments/environment_details/components/deployment_triggerer.vue', () => {
  const triggererData = {
    id: 'gid://gitlab/User/1',
    webUrl: 'http://gdk.test:3000/root',
    name: 'Administrator',
    avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  };
  let wrapper;

  const createWrapper = ({ triggerer }) => {
    return mountExtended(DeploymentTriggerer, {
      propsData: {
        triggerer,
      },
    });
  };

  describe('when the triggerer data exists', () => {
    beforeEach(() => {
      wrapper = createWrapper({ triggerer: triggererData });
    });

    it('should render an avatar link with a correct href', () => {
      const triggererAvatarLink = wrapper.findComponent(GlAvatarLink);
      expect(triggererAvatarLink.exists()).toBe(true);
      expect(triggererAvatarLink.attributes().href).toBe(triggererData.webUrl);
    });

    it('should render an avatar', () => {
      const triggererAvatar = wrapper.findComponent(GlAvatar);
      expect(triggererAvatar.exists()).toBe(true);
      expect(triggererAvatar.attributes().title).toBe(triggererData.name);
      expect(triggererAvatar.props().src).toBe(triggererData.avatarUrl);
    });
  });

  describe('when the triggerer data does not exist', () => {
    beforeEach(() => {
      wrapper = createWrapper({ triggerer: null });
    });

    it('should render nothing', () => {
      const avatarLink = wrapper.findComponent(GlAvatarLink);
      expect(avatarLink.exists()).toBe(false);
    });
  });
});
