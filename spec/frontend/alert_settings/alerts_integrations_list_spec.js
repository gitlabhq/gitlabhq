import { GlTable } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AlertIntegrationsList, {
  i18n,
} from '~/alerts_settings/components/alerts_integrations_list.vue';

const mockIntegrations = [
  {
    status: true,
    name: 'Integration 1',
    type: 'HTTP endpoint',
  },
  {
    status: false,
    name: 'Integration 2',
    type: 'HTTP endpoint',
  },
];

describe('AlertIntegrationsList', () => {
  let wrapper;

  function mountComponent(propsData = {}) {
    wrapper = shallowMount(AlertIntegrationsList, {
      propsData: {
        integrations: mockIntegrations,
        ...propsData,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  beforeEach(() => {
    mountComponent();
  });

  const findTableComponent = () => wrapper.find(GlTable);

  it('renders a table', () => {
    expect(findTableComponent().exists()).toBe(true);
    expect(findTableComponent().attributes('empty-text')).toBe(i18n.emptyState);
  });
});
