import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContactFormWrapper from '~/crm/contacts/components/contact_form_wrapper.vue';
import ContactForm from '~/crm/components/form.vue';
import getGroupContactsQuery from '~/crm/contacts/components/graphql/get_group_contacts.query.graphql';
import createContactMutation from '~/crm/contacts/components/graphql/create_contact.mutation.graphql';
import updateContactMutation from '~/crm/contacts/components/graphql/update_contact.mutation.graphql';

describe('Customer relations contact form wrapper', () => {
  let wrapper;

  const findContactForm = () => wrapper.findComponent(ContactForm);

  const $apollo = {
    queries: {
      contacts: {
        loading: false,
      },
    },
  };
  const $route = {
    params: {
      id: 7,
    },
  };
  const contacts = [{ id: 'gid://gitlab/CustomerRelations::Contact/7' }];

  const mountComponent = ({ isEditMode = false } = {}) => {
    wrapper = shallowMountExtended(ContactFormWrapper, {
      propsData: {
        isEditMode,
      },
      provide: {
        groupFullPath: 'flightjs',
        groupId: 26,
      },
      mocks: {
        $apollo,
        $route,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('in edit mode', () => {
    it('should render contact form with correct props', () => {
      mountComponent({ isEditMode: true });

      const contactForm = findContactForm();
      expect(contactForm.props('fields')).toHaveLength(5);
      expect(contactForm.props('title')).toBe('Edit contact');
      expect(contactForm.props('successMessage')).toBe('Contact has been updated.');
      expect(contactForm.props('mutation')).toBe(updateContactMutation);
      expect(contactForm.props('getQuery')).toMatchObject({
        query: getGroupContactsQuery,
        variables: { groupFullPath: 'flightjs' },
      });
      expect(contactForm.props('getQueryNodePath')).toBe('group.contacts');
      expect(contactForm.props('existingId')).toBe(contacts[0].id);
      expect(contactForm.props('additionalCreateParams')).toMatchObject({
        groupId: 'gid://gitlab/Group/26',
      });
    });
  });

  describe('in create mode', () => {
    it('should render contact form with correct props', () => {
      mountComponent();

      const contactForm = findContactForm();
      expect(contactForm.props('fields')).toHaveLength(5);
      expect(contactForm.props('title')).toBe('New contact');
      expect(contactForm.props('successMessage')).toBe('Contact has been added.');
      expect(contactForm.props('mutation')).toBe(createContactMutation);
      expect(contactForm.props('getQuery')).toMatchObject({
        query: getGroupContactsQuery,
        variables: { groupFullPath: 'flightjs' },
      });
      expect(contactForm.props('getQueryNodePath')).toBe('group.contacts');
      expect(contactForm.props('existingId')).toBeNull();
      expect(contactForm.props('additionalCreateParams')).toMatchObject({
        groupId: 'gid://gitlab/Group/26',
      });
    });
  });
});
