import { GlEmptyState, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/terraform/components/empty_state.vue';
import InitCommandModal from '~/terraform/components/init_command_modal.vue';

describe('EmptyStateComponent', () => {
  let wrapper;

  const propsData = {
    image: '/image/path',
  };
  const docsUrl = '/help/user/infrastructure/iac/terraform_state';
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findButton = () => wrapper.findComponent(GlButton);
  const findCopyModal = () => wrapper.findComponent(InitCommandModal);
  const findCopyButton = () => wrapper.find('[data-testid="terraform-state-copy-init-command"]');

  beforeEach(() => {
    wrapper = shallowMount(EmptyState, { propsData });
  });

  it('should render content', () => {
    expect(findEmptyState().props('title')).toBe(
      "Your project doesn't have any Terraform state files",
    );
  });

  it('buttons explore documentation should have a link to the GitLab managed Terraform states docs', () => {
    expect(findButton().attributes('href')).toBe(docsUrl);
  });

  describe('copy command button', () => {
    it('displays a copy init command button', () => {
      expect(findCopyButton().text()).toBe('Copy Terraform init command');
    });

    it('opens the modal on copy button click', async () => {
      await findCopyButton().vm.$emit('click');

      expect(findCopyModal().isVisible()).toBe(true);
    });
  });
});
