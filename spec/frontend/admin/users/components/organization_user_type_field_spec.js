import { GlFormRadio } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import OrganizationUserTypeField from '~/admin/users/components/organization_user_type_field.vue';

describe('OrganizationUserTypeField', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(OrganizationUserTypeField, { propsData });
  };

  const findRadios = () => wrapper.findAllComponents(GlFormRadio);
  const findRadioInputs = () => wrapper.findAll('input[type="radio"]');
  const findCheckedValue = () =>
    findRadioInputs().wrappers.find((input) => input.element.checked)?.element.value;

  describe('when no optional props are passed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders label and label description', () => {
      expect(wrapper.findByText('Organization user type').exists()).toBe(true);
      expect(
        wrapper
          .findByText(
            'Define user access to groups, projects, users, and features in this Organization.',
          )
          .exists(),
      ).toBe(true);
    });

    it('renders a radio for each organization user type', () => {
      expect(
        findRadios().wrappers.map((radio) => [radio.props('value'), trimText(radio.text())]),
      ).toEqual([
        ['default', 'Organization regular user Access to their groups and projects.'],
        [
          'owner',
          'Organization administrator Full access to all groups, projects, users, features, and the Organization admin area.',
        ],
      ]);
    });

    it('names the radio inputs so the form submits the access level', () => {
      expect(findRadioInputs().wrappers.map((input) => input.attributes('name'))).toEqual([
        'user[organization_access_level]',
        'user[organization_access_level]',
      ]);
    });

    it('checks the regular user radio', () => {
      expect(findCheckedValue()).toBe('default');
    });
  });

  describe('when inputName prop is passed', () => {
    beforeEach(() => {
      createComponent({
        propsData: { inputName: 'user[organization_users_attributes][][access_level]' },
      });
    });

    it('names the radio inputs with it', () => {
      expect(findRadioInputs().wrappers.map((input) => input.attributes('name'))).toEqual([
        'user[organization_users_attributes][][access_level]',
        'user[organization_users_attributes][][access_level]',
      ]);
    });
  });

  describe('when initialAccessLevel prop is passed', () => {
    beforeEach(() => {
      createComponent({ propsData: { initialAccessLevel: 'owner' } });
    });

    it('checks the matching radio', () => {
      expect(findCheckedValue()).toBe('owner');
    });
  });

  describe('when a different radio is selected', () => {
    beforeEach(async () => {
      createComponent();

      await findRadioInputs().at(1).setChecked();
    });

    it('checks the selected radio', () => {
      expect(findCheckedValue()).toBe('owner');
    });
  });
});
