import { nextTick } from 'vue';
import GroupSettingsCreateOrganization from '~/groups/settings/create_organization/components/app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import ReconciliationModal from '~/groups/settings/create_organization/components/modal.vue';

describe('GroupSettingsCreateOrganization', () => {
  let wrapper;

  const defaultPropsData = {
    groupFullPath: 'mock-group',
    groupGid: convertToGraphQLId(TYPENAME_GROUP, 1),
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(GroupSettingsCreateOrganization, {
      propsData: defaultPropsData,
    });
  };

  const findReconciliationModal = () => wrapper.findComponent(ReconciliationModal);
  const findStartCreatingOrganizationButton = () =>
    wrapper.findComponentByTestId('start-creating-organization-button');

  beforeEach(createComponent);

  it('passes group props to reconciliation modal', () => {
    expect(findReconciliationModal().props()).toMatchObject(defaultPropsData);
  });

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
