import { GlTab } from '@gitlab/ui';

import { s__ } from '~/locale';
import ContributedProjectsTab from '~/profile/components/contributed_projects_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('ContributedProjectsTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ContributedProjectsTab);
  };

  it('renders `GlTab` and sets `title` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).attributes('title')).toBe(
      s__('UserProfile|Contributed projects'),
    );
  });
});
