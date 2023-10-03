import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import OrganizationsIndexApp from '~/organizations/index/components/app.vue';
import OrganizationsView from '~/organizations/index/components/organizations_view.vue';
import { MOCK_NEW_ORG_URL } from '../mock_data';

describe('OrganizationsIndexApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(OrganizationsIndexApp, {
      provide: {
        newOrganizationUrl: MOCK_NEW_ORG_URL,
      },
    });
  };

  const findNewOrganizationButton = () => wrapper.findComponent(GlButton);
  const findOrganizationsView = () => wrapper.findComponent(OrganizationsView);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders new organization button with correct link', () => {
      expect(findNewOrganizationButton().attributes('href')).toBe(MOCK_NEW_ORG_URL);
    });

    it('renders the organizations view', () => {
      expect(findOrganizationsView().exists()).toBe(true);
    });
  });
});
