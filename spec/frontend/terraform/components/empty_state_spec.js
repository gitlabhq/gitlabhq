import { GlEmptyState, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/terraform/components/empty_state.vue';

describe('EmptyStateComponent', () => {
  let wrapper;

  const propsData = {
    image: '/image/path',
  };
  const docsUrl = '/help/user/infrastructure/iac/terraform_state';
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    wrapper = shallowMount(EmptyState, { propsData });
  });

  it('should render content', () => {
    expect(findEmptyState().props('title')).toBe(
      "Your project doesn't have any Terraform state files",
    );
  });

  it('should have a link to the GitLab managed Terraform states docs', () => {
    expect(findLink().attributes('href')).toBe(docsUrl);
  });
});
