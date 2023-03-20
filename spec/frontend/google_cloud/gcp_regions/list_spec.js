import { mount } from '@vue/test-utils';
import { GlButton, GlEmptyState, GlTable } from '@gitlab/ui';
import GcpRegionsList from '~/google_cloud/gcp_regions/list.vue';

describe('google_cloud/gcp_regions/list', () => {
  describe('when the project does not have any configured regions', () => {
    let wrapper;

    const findEmptyState = () => wrapper.findComponent(GlEmptyState);
    const findButtonInEmptyState = () => findEmptyState().findComponent(GlButton);

    beforeEach(() => {
      const propsData = {
        list: [],
        createUrl: '#create-url',
        emptyIllustrationUrl: '#empty-illustration-url',
      };
      wrapper = mount(GcpRegionsList, { propsData });
    });

    it('shows the empty state component', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
    it('shows the link to create new service accounts', () => {
      const button = findButtonInEmptyState();
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Configure regions');
      expect(button.attributes('href')).toBe('#create-url');
    });
  });

  describe('when three gcp regions are passed via props', () => {
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
      wrapper = mount(GcpRegionsList, { propsData });
    });

    it('shows the title', () => {
      expect(findTitle().text()).toBe('Regions');
    });

    it('shows the description', () => {
      expect(findDescription().text()).toBe(
        'Configure your environments to be deployed to specific geographical regions',
      );
    });

    it('shows the table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('table must have three rows + header row', () => {
      expect(findRows()).toHaveLength(4);
    });

    it('shows the link to create new service accounts', () => {
      const button = findButton();
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Configure regions');
      expect(button.attributes('href')).toBe('#create-url');
    });
  });
});
