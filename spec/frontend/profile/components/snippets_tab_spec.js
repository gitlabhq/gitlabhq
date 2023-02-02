import { GlTab } from '@gitlab/ui';

import { s__ } from '~/locale';
import SnippetsTab from '~/profile/components/snippets_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('SnippetsTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(SnippetsTab);
  };

  it('renders `GlTab` and sets `title` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).attributes('title')).toBe(s__('UserProfile|Snippets'));
  });
});
