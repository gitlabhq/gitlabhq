import { GlTab } from '@gitlab/ui';

import PersonalProjectsTab from '~/profile/components/personal_projects_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('PersonalProjectsTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(PersonalProjectsTab);
  };

  it('renders `GlTab` and sets `title` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).attributes('title')).toBe('Personal projects');
  });
});
