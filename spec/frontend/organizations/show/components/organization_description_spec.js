import { mountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationDescription from '~/organizations/show/components/organization_description.vue';

describe('OrganizationDescription', () => {
  let wrapper;

  const defaultPropsData = {
    organization: {
      id: 1,
      name: 'GitLab',
      description_html: '<h1>Foo bar description</h1><script>alert("foo")</script>',
    },
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(OrganizationDescription, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('when organization has description', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders description as safe HTML', () => {
      expect(wrapper.element.innerHTML).toBe('<h1>Foo bar description</h1>');
    });
  });

  describe('when organization does not have description', () => {
    beforeEach(() => {
      createComponent({
        propsData: { organization: { ...defaultPropsData.organization, description_html: '' } },
      });
    });

    it('renders nothing', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });
  });
});
