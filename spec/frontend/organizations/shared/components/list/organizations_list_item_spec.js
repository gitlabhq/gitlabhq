import { GlAvatarLabeled } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import OrganizationsListItem from '~/organizations/shared/components/list/organizations_list_item.vue';
import { organizations } from '~/organizations/mock_data';

const MOCK_ORGANIZATION = organizations[0];

describe('OrganizationsListItem', () => {
  let wrapper;

  const defaultProps = {
    organization: MOCK_ORGANIZATION,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(OrganizationsListItem, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGlAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findHTMLOrganizationDescription = () =>
    wrapper.findByTestId('organization-description-html');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlAvatarLabeled with correct data', () => {
      expect(findGlAvatarLabeled().attributes()).toMatchObject({
        'entity-id': getIdFromGraphQLId(MOCK_ORGANIZATION.id).toString(),
        'entity-name': MOCK_ORGANIZATION.name,
        src: MOCK_ORGANIZATION.avatarUrl,
        label: MOCK_ORGANIZATION.name,
        labellink: MOCK_ORGANIZATION.webUrl,
      });
    });
  });

  describe('organization description', () => {
    const descriptionHtml = '<p>Foo bar</p>';

    describe('is a HTML description', () => {
      beforeEach(() => {
        createComponent({ organization: { ...MOCK_ORGANIZATION, descriptionHtml } });
      });

      it('renders HTML description', () => {
        expect(findHTMLOrganizationDescription().html()).toContain(descriptionHtml);
      });
    });

    describe('is not a HTML description', () => {
      beforeEach(() => {
        createComponent({
          organization: { ...MOCK_ORGANIZATION, descriptionHtml: null },
        });
      });

      it('does not render HTML description', () => {
        expect(findHTMLOrganizationDescription().exists()).toBe(false);
      });
    });
  });
});
