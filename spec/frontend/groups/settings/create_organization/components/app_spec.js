import { nextTick } from 'vue';
import GroupSettingsCreateOrganization from '~/groups/settings/create_organization/components/app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReconciliationModal from '~/groups/settings/create_organization/components/modal.vue';

describe('GroupSettingsCreateOrganization', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(GroupSettingsCreateOrganization);
  };

  const findReconciliationModal = () => wrapper.findComponent(ReconciliationModal);
  const findStartCreatingOrganizationButton = () =>
    wrapper.findComponentByTestId('start-creating-organization-button');

  beforeEach(createComponent);

  it('opens reconciliation modal when clicked', async () => {
    expect(findReconciliationModal().props('visible')).toBe(false);
    findStartCreatingOrganizationButton().vm.$emit('click');
    await nextTick();

    expect(findReconciliationModal().props('visible')).toBe(true);
  });

  it('closes modal when change event is emitted with false', async () => {
    findStartCreatingOrganizationButton().vm.$emit('click');

    await nextTick();
    expect(findReconciliationModal().props('visible')).toBe(true);

    findReconciliationModal().vm.$emit('change', false);
    await nextTick();

    expect(findReconciliationModal().props('visible')).toBe(false);
  });
});
