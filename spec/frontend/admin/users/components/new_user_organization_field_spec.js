import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NewUserOrganizationField from '~/admin/users/components/new_user_organization_field.vue';
import OrganizationUserTypeField from '~/admin/users/components/organization_user_type_field.vue';
import OrganizationSelect from '~/vue_shared/components/entity_select/organization_select.vue';
import organizationsQuery from '~/organizations/shared/graphql/queries/organizations.query.graphql';
import { ACCESS_LEVEL_OWNER, ACCESS_LEVEL_DEFAULT } from '~/organizations/shared/constants';

describe('NewUserOrganizationField', () => {
  let wrapper;

  const defaultPropsData = {
    hasMultipleOrganizations: false,
    initialOrganization: {
      id: 1,
      name: 'Default',
      web_url: '/o/default/-/overview',
      avatarUrl: 'avatar.jpg',
    },
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(NewUserOrganizationField, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  const findHiddenOrganizationField = () =>
    wrapper.find('input[name="user[organization_id]"][type="hidden"]');
  const findHiddenOrganizationUserField = () =>
    wrapper.find('input[name="user[organization_users_attributes][][id]"][type="hidden"]');
  const findOrganizationSelect = () => wrapper.findComponent(OrganizationSelect);
  const findOrganizationUserTypeField = () => wrapper.findComponent(OrganizationUserTypeField);

  describe('when `hasMultipleOrganizations` prop is `false`', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders hidden field with initial organization id', () => {
      expect(findHiddenOrganizationField().element.value).toBe(
        `${defaultPropsData.initialOrganization.id}`,
      );
    });

    it('does not render organization select', () => {
      expect(findOrganizationSelect().exists()).toBe(false);
    });
  });

  describe('when `hasMultipleOrganizations` prop is `true`', () => {
    beforeEach(() => {
      createComponent({ propsData: { hasMultipleOrganizations: true } });
    });

    it('does not render hidden field with initial organization id', () => {
      expect(findHiddenOrganizationField().exists()).toBe(false);
    });

    it('renders organization select with default organization selected', () => {
      expect(findOrganizationSelect().props()).toMatchObject({
        searchable: false,
        query: organizationsQuery,
        queryPath: 'organizations',
        initialSelection: {
          text: defaultPropsData.initialOrganization.name,
          value: defaultPropsData.initialOrganization.id,
        },
        inputName: 'user[organization_id]',
      });
    });
  });

  it('renders organization user type field', () => {
    createComponent();

    expect(findOrganizationUserTypeField().exists()).toBe(true);
  });

  it('passes initialAccessLevel prop to organization user type field', () => {
    createComponent();

    expect(findOrganizationUserTypeField().props('initialAccessLevel')).toBe(ACCESS_LEVEL_DEFAULT);
  });

  it('passes organizationUserTypeInputName prop to organization user type field', () => {
    createComponent({
      propsData: {
        organizationUserTypeInputName: 'user[organization_users_attributes][][access_level]',
      },
    });

    expect(findOrganizationUserTypeField().props('inputName')).toBe(
      'user[organization_users_attributes][][access_level]',
    );
  });

  it('does not render hidden input with organization user id', () => {
    createComponent();

    expect(findHiddenOrganizationUserField().exists()).toBe(false);
  });

  describe('when organizationUser prop is passed', () => {
    const organizationUser = { id: 1, accessLevel: ACCESS_LEVEL_OWNER };

    beforeEach(() => {
      createComponent({
        propsData: { organizationUser },
      });
    });

    it('renders hidden input with organization user id', () => {
      expect(findHiddenOrganizationUserField().element.value).toBe(organizationUser.id.toString());
    });

    it('passes initialAccessLevel prop to organization user type field', () => {
      expect(findOrganizationUserTypeField().props('initialAccessLevel')).toBe(
        organizationUser.accessLevel,
      );
    });
  });
});
