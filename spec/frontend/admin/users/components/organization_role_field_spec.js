import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationRoleField from '~/admin/users/components/organization_role_field.vue';
import { ACCESS_LEVEL_DEFAULT, ACCESS_LEVEL_OWNER } from '~/organizations/shared/constants';

describe('OrganizationRoleField', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(OrganizationRoleField, { propsData });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findHiddenInput = () => wrapper.find('input[type="hidden"]');

  beforeEach(() => {
    createComponent();
  });

  it('renders listbox with User and Owner roles', () => {
    expect(findListbox().props()).toMatchObject({
      selected: ACCESS_LEVEL_DEFAULT,
      items: [
        {
          text: 'User',
          value: ACCESS_LEVEL_DEFAULT,
        },
        {
          text: 'Owner',
          value: ACCESS_LEVEL_OWNER,
        },
      ],
    });
  });

  it('renders hidden input', () => {
    expect(findHiddenInput().element.value).toBe(ACCESS_LEVEL_DEFAULT);
    expect(findHiddenInput().attributes('name')).toBe('user[organization_access_level]');
  });

  describe('when listbox is changed', () => {
    beforeEach(() => {
      findListbox().vm.$emit('select', ACCESS_LEVEL_OWNER);
    });

    it('updates hidden input value', () => {
      expect(findHiddenInput().element.value).toBe(ACCESS_LEVEL_OWNER);
    });
  });

  describe('when initialAccessLevel prop is passed', () => {
    beforeEach(() => {
      createComponent({ propsData: { initialAccessLevel: ACCESS_LEVEL_OWNER } });
    });

    it('sets initial value of listbox', () => {
      expect(findListbox().props('selected')).toBe(ACCESS_LEVEL_OWNER);
    });

    it('sets hidden input value', () => {
      expect(findHiddenInput().element.value).toBe(ACCESS_LEVEL_OWNER);
    });
  });
});
