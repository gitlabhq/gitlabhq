import { GlAvatarLabeled } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NewUserOrganizationField from '~/admin/users/components/new_user_organization_field.vue';
import OrganizationRoleField from '~/admin/users/components/organization_role_field.vue';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import OrganizationSelect from '~/vue_shared/components/entity_select/organization_select.vue';
import organizationsQuery from '~/organizations/shared/graphql/queries/organizations.query.graphql';

describe('NewUserOrganizationField', () => {
  let wrapper;

  const defaultPropsData = {
    hasMultipleOrganizations: false,
    initialOrganization: {
      id: 1,
      name: 'Default',
      web_url: '/-/organizations/default',
      avatarUrl: 'avatar.jpg',
    },
  };

  const createComponent = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(NewUserOrganizationField, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatarLabeled);
  const findHiddenOrganizationField = () =>
    wrapper.findByRole('textbox', { hidden: true, label: NewUserOrganizationField.inputName });
  const findOrganizationSelect = () => wrapper.findComponent(OrganizationSelect);
  const findOrganizationRoleField = () => wrapper.findComponent(OrganizationRoleField);

  describe('when `hasMultipleOrganizations` prop is `false`', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders avatar', () => {
      expect(findAvatar().attributes()).toMatchObject({
        'entity-id': defaultPropsData.initialOrganization.id.toString(),
        'entity-name': defaultPropsData.initialOrganization.name,
        label: defaultPropsData.initialOrganization.name,
        shape: AVATAR_SHAPE_OPTION_RECT,
        src: defaultPropsData.initialOrganization.avatarUrl,
      });
    });

    it('renders hidden field with initial organization id', () => {
      expect(findHiddenOrganizationField().element.value).toBe(
        `${defaultPropsData.initialOrganization.id}`,
      );
    });
  });

  describe('when `hasMultipleOrganizations` prop is `true`', () => {
    beforeEach(() => {
      createComponent({ propsData: { hasMultipleOrganizations: true } });
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
      });
    });
  });

  it('renders role field', () => {
    createComponent();

    expect(findOrganizationRoleField().exists()).toBe(true);
  });
});
