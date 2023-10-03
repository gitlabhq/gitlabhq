import { GlAvatarLabeled } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import OrganizationsListItem from '~/organizations/index/components/organizations_list_item.vue';
import { organizations } from '~/organizations/mock_data';

const MOCK_ORGANIZATION = organizations[0];

describe('OrganizationsListItem', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(OrganizationsListItem, {
      propsData: {
        organization: MOCK_ORGANIZATION,
      },
    });
  };

  const findGlAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlAvatarLabeled with correct description', () => {
      expect(findGlAvatarLabeled().text()).toBe(MOCK_ORGANIZATION.description);
    });

    it('renders GlAvatarLabeled with correct data', () => {
      expect(findGlAvatarLabeled().attributes('entity-id')).toBe(
        getIdFromGraphQLId(MOCK_ORGANIZATION.id).toString(),
      );
      expect(findGlAvatarLabeled().attributes('src')).toBe(
        MOCK_ORGANIZATION.avatarUrl || undefined,
      );
      expect(findGlAvatarLabeled().attributes('entity-name')).toBe(MOCK_ORGANIZATION.name);
      expect(findGlAvatarLabeled().attributes('label')).toBe(MOCK_ORGANIZATION.name);
      expect(findGlAvatarLabeled().attributes('label-link')).toBe(
        MOCK_ORGANIZATION.webUrl || undefined,
      );
    });
  });
});
