import { shallowMount } from '@vue/test-utils';
import { GlTab } from '@gitlab/ui';
import IncidentTabs from '~/issue_show/components/incident_tabs.vue';
import { descriptionProps } from '../mock_data';
import DescriptionComponent from '~/issue_show/components/description.vue';

describe('Incident Tabs component', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMount(IncidentTabs, {
      propsData: {
        ...descriptionProps,
      },
      stubs: {
        DescriptionComponent: true,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  const findTabs = () => wrapper.findAll(GlTab);
  const findSummaryTab = () => findTabs().at(0);
  const findDescriptionComponent = () => wrapper.find(DescriptionComponent);

  describe('default state', () => {
    it('renders the summary tab', async () => {
      expect(findTabs()).toHaveLength(1);
      expect(findSummaryTab().exists()).toBe(true);
      expect(findSummaryTab().attributes('title')).toBe('Summary');
    });

    it('renders the description component', () => {
      expect(findDescriptionComponent().exists()).toBe(true);
    });

    it('passes all props to the description component', () => {
      expect(findDescriptionComponent().props()).toMatchObject(descriptionProps);
    });
  });
});
