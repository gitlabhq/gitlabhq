import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AddOrganizationUsersTrigger from '~/organizations/admin/components/add_organization_users_trigger.vue';
import AddOrganizationUsersModal from '~/organizations/admin/components/add_organization_users_modal.vue';

describe('AddOrganizationUsersTrigger', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(AddOrganizationUsersTrigger, {
      stubs: { AddOrganizationUsersModal: true },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(AddOrganizationUsersModal);

  beforeEach(() => {
    createComponent();
  });

  it('renders a trigger button', () => {
    expect(findButton().exists()).toBe(true);
  });

  it('uses the confirm variant', () => {
    expect(findButton().props('variant')).toBe('confirm');
  });

  it('modal is hidden by default', () => {
    expect(findModal().props('visible')).toBe(false);
  });

  it('opens the modal when the button is clicked', async () => {
    await findButton().vm.$emit('click');

    expect(findModal().props('visible')).toBe(true);
  });

  it('closes the modal on change event', async () => {
    await findButton().vm.$emit('click');
    await findModal().vm.$emit('change', false);

    expect(findModal().props('visible')).toBe(false);
  });
});
