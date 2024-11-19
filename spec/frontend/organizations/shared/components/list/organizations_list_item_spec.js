import { GlAvatarLabeled } from '@gitlab/ui';
import currentUserOrganizationsGraphQlResponse from 'test_fixtures/graphql/organizations/current_user_organizations.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import OrganizationsListItem from '~/organizations/shared/components/list/organizations_list_item.vue';

describe('OrganizationsListItem', () => {
  let wrapper;

  const {
    data: {
      currentUser: {
        organizations: {
          nodes: [organization],
        },
      },
    },
  } = currentUserOrganizationsGraphQlResponse;

  const defaultProps = {
    organization,
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
        'entity-id': getIdFromGraphQLId(organization.id).toString(),
        'entity-name': organization.name,
        src: organization.avatarUrl,
        label: organization.name,
        labellink: organization.webUrl,
      });
    });
  });

  describe('organization description', () => {
    const descriptionHtml = '<p>Foo bar</p>';

    describe('is a HTML description', () => {
      beforeEach(() => {
        createComponent({ organization: { ...organization, descriptionHtml } });
      });

      it('renders HTML description', () => {
        expect(findHTMLOrganizationDescription().html()).toContain(descriptionHtml);
      });
    });

    describe('is not a HTML description', () => {
      beforeEach(() => {
        createComponent({
          organization: { ...organization, descriptionHtml: null },
        });
      });

      it('does not render HTML description', () => {
        expect(findHTMLOrganizationDescription().exists()).toBe(false);
      });
    });
  });
});
