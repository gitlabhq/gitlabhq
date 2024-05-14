import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HomePanel from '~/pages/projects/home_panel/components/home_panel.vue';
import HomePanelActions from '~/pages/projects/home_panel/components/home_panel_actions.vue';

describe('HomePanel', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(HomePanel);
  };

  const findHomePanelActions = () => wrapper.findComponent(HomePanelActions);

  it('renders components as expected', () => {
    createComponent();

    expect(findHomePanelActions().exists()).toBe(true);
  });
});
