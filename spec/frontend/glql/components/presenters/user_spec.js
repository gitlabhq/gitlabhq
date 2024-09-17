import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserPresenter from '~/glql/components/presenters/user.vue';
import { MOCK_USER } from '../../mock_data';

describe('UserPresenter', () => {
  let wrapper;

  const createWrapper = ({ data }) => {
    wrapper = shallowMountExtended(UserPresenter, {
      propsData: { data },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);

  it('correctly renders a user link', () => {
    createWrapper({ data: MOCK_USER });

    const link = findLink();
    expect(link.attributes('href')).toBe(MOCK_USER.webUrl);
    expect(link.attributes('title')).toBe(MOCK_USER.name);
    expect(link.text()).toBe(`@${MOCK_USER.username}`);
  });

  it('adds current-user class when user is the current user', () => {
    gon.current_username = MOCK_USER.username;

    createWrapper({ data: MOCK_USER });

    const link = findLink();
    expect(link.classes('current-user')).toBe(true);
  });
});
