import { GlTab } from '@gitlab/ui';

import StarredProjectsTab from '~/profile/components/starred_projects_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('StarredProjectsTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(StarredProjectsTab);
  };

  it('renders `GlTab` and sets `title` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).attributes('title')).toBe('Starred projects');
  });
});
