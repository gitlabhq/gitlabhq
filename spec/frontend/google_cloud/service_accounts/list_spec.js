import { mount } from '@vue/test-utils';
import { GlAlert, GlButton, GlEmptyState, GlTable } from '@gitlab/ui';
import ServiceAccountsList from '~/google_cloud/service_accounts/list.vue';

describe('google_cloud/service_accounts/list', () => {
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
      wrapper = mount(ServiceAccountsList, { propsData });
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
      expect(button.text()).toBe(ServiceAccountsList.i18n.createServiceAccount);
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
    const findSecretManagerTip = () => wrapper.findComponent(GlAlert);

    beforeEach(() => {
      const propsData = {
        list: [{}, {}, {}],
        createUrl: '#create-url',
        emptyIllustrationUrl: '#empty-illustration-url',
      };
      wrapper = mount(ServiceAccountsList, { propsData });
    });

    it('shows the title', () => {
      expect(findTitle().text()).toBe(ServiceAccountsList.i18n.serviceAccountsTitle);
    });

    it('shows the description', () => {
      expect(findDescription().text()).toBe(ServiceAccountsList.i18n.serviceAccountsDescription);
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
      expect(button.text()).toBe(ServiceAccountsList.i18n.createServiceAccount);
      expect(button.attributes('href')).toBe('#create-url');
    });

    it('must contain secret managers tip', () => {
      const tip = findSecretManagerTip();
      const expectedText = ServiceAccountsList.i18n.secretManagersDescription.substr(0, 48);
      expect(tip.text()).toContain(expectedText);
    });
  });
});
