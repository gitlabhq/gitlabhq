import { shallowMount } from '@vue/test-utils';
import OrganizationsList from '~/organizations/index/components/organizations_list.vue';
import OrganizationsListItem from '~/organizations/index/components/organizations_list_item.vue';
import { organizations } from '~/organizations/mock_data';

describe('OrganizationsList', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(OrganizationsList, {
      propsData: {
        organizations,
      },
    });
  };

  const findAllOrganizationsListItem = () => wrapper.findAllComponents(OrganizationsListItem);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a list item for each organization', () => {
      expect(findAllOrganizationsListItem()).toHaveLength(organizations.length);
    });
  });
});
