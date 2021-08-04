import { GlEmptyState, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/terraform/components/empty_state.vue';

describe('EmptyStateComponent', () => {
  let wrapper;

  const propsData = {
    image: '/image/path',
  };
  const docsUrl = '/help/user/infrastructure/terraform_state';
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    wrapper = shallowMount(EmptyState, { propsData, stubs: { GlEmptyState, GlLink } });
  });

  it('should render content', () => {
    expect(findEmptyState().exists()).toBe(true);
    expect(wrapper.text()).toContain('Get started with Terraform');
  });

  it('should have a link to the GitLab managed Terraform States docs', () => {
    expect(findLink().attributes('href')).toBe(docsUrl);
  });
});
