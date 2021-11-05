import { mount } from '@vue/test-utils';
import { GlButton, GlEmptyState, GlTable } from '@gitlab/ui';
import ServiceAccounts from '~/google_cloud/components/service_accounts.vue';

describe('ServiceAccounts component', () => {
  describe('when the project does not have any service accounts', () => {
    let wrapper;

    const findEmptyState = () => wrapper.findComponent(GlEmptyState);
    const findButtonInEmptyState = () => findEmptyState().findComponent(GlButton);

    beforeEach(() => {
      const propsData = {
        list: [],
        createUrl: '#create-url',
        emptyIllustrationUrl: '#empty-illustration-url',
      };
      wrapper = mount(ServiceAccounts, { propsData });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('shows the empty state component', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
    it('shows the link to create new service accounts', () => {
      const button = findButtonInEmptyState();
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Create service account');
      expect(button.attributes('href')).toBe('#create-url');
    });
  });

  describe('when three service accounts are passed via props', () => {
    let wrapper;

    const findTitle = () => wrapper.find('h2');
    const findDescription = () => wrapper.find('p');
    const findTable = () => wrapper.findComponent(GlTable);
    const findRows = () => findTable().findAll('tr');
    const findButton = () => wrapper.findComponent(GlButton);

    beforeEach(() => {
      const propsData = {
        list: [{}, {}, {}],
        createUrl: '#create-url',
        emptyIllustrationUrl: '#empty-illustration-url',
      };
      wrapper = mount(ServiceAccounts, { propsData });
    });

    it('shows the title', () => {
      expect(findTitle().text()).toBe('Service Accounts');
    });

    it('shows the description', () => {
      expect(findDescription().text()).toBe(
        'Service Accounts keys authorize GitLab to deploy your Google Cloud project',
      );
    });

    it('shows the table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('table must have three rows + header row', () => {
      expect(findRows().length).toBe(4);
    });

    it('shows the link to create new service accounts', () => {
      const button = findButton();
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Create service account');
      expect(button.attributes('href')).toBe('#create-url');
    });
  });
});
