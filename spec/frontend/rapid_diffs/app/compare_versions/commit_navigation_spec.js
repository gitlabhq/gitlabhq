import { shallowMount } from '@vue/test-utils';
import { GlLink, GlButton } from '@gitlab/ui';
import CommitNavigation from '~/rapid_diffs/app/compare_versions/commit_navigation.vue';

describe('CommitNavigation', () => {
  let wrapper;

  const commit = {
    id: 'abc123full',
    short_id: 'abc123',
    commit_url: '/project/-/commit/abc123full',
    diff_refs: { base_sha: 'p', start_sha: 'p', head_sha: 'abc123full' },
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CommitNavigation, {
      propsData: { commit, ...props },
    });
  };

  it('shows commit short_id with link', () => {
    createComponent();

    const link = wrapper.findComponent(GlLink);
    expect(link.attributes('href')).toBe('/project/-/commit/abc123full');
    expect(link.text()).toBe('abc123');
  });

  it('shows latest version link', () => {
    createComponent();

    const button = wrapper.findComponent(GlButton);
    expect(button.text()).toBe('Show latest version');
    expect(button.attributes('href')).toBeDefined();
  });
});
