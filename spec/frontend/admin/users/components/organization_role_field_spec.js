import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationRoleField from '~/admin/users/components/organization_role_field.vue';
import { ACCESS_LEVEL_DEFAULT, ACCESS_LEVEL_OWNER } from '~/organizations/shared/constants';

describe('OrganizationRoleField', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(OrganizationRoleField);
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
  });

  describe('when listbox is changed', () => {
    beforeEach(() => {
      findListbox().vm.$emit('select', ACCESS_LEVEL_OWNER);
    });

    it('updates hidden input value', () => {
      expect(findHiddenInput().element.value).toBe(ACCESS_LEVEL_OWNER);
    });
  });
});
