import { mount } from '@vue/test-utils';
import { GlTable, GlLink, GlButton, GlPagination, GlSprintf, GlAlert } from '@gitlab/ui';
import AgentsConfigsTable from '~/clusters_list/components/agents_configs_table.vue';
import { MAX_LIST_COUNT, MAX_CONFIGS_SHOWN } from '~/clusters_list/constants';

describe('AgentsConfigsTable', () => {
  let wrapper;

  const defaultProps = {
    configs: [
      { name: 'agent-1', path: 'path/to/agent-1', webPath: '/agent-1' },
      { name: 'agent-2', path: 'path/to/agent-2', webPath: '/agent-2' },
    ],
  };

  const createComponent = ({ props = {}, canAddCluster = true } = {}) => {
    wrapper = mount(AgentsConfigsTable, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        canAddCluster,
      },
      stubs: { GlSprintf },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findTableRows = () => findTable().findAll('tbody > tr');
  const findRowLink = (at) => findTableRows().at(at).findComponent(GlLink);
  const findAllButtons = () => wrapper.findAllComponents(GlButton);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findAlert = () => wrapper.findComponent(GlAlert);

  it('renders table with correct props', () => {
    createComponent();

    expect(findTableRows()).toHaveLength(2);
    expect(findTable().props('fields')).toHaveLength(2);
  });

  it('renders configuration links correctly', () => {
    createComponent();

    expect(findRowLink(0).attributes('href')).toBe('/agent-1');
    expect(findRowLink(0).text()).toBe('path/to/agent-1');

    expect(findRowLink(1).attributes('href')).toBe('/agent-2');
    expect(findRowLink(1).text()).toBe('path/to/agent-2');
  });

  it('renders register buttons when canAddCluster is true', () => {
    createComponent();

    expect(findAllButtons()).toHaveLength(2);
    expect(findAllButtons().at(0).text()).toBe('Register an agent');
  });

  it('does not render register buttons when canAddCluster is false', () => {
    createComponent({ canAddCluster: false });

    expect(findAllButtons()).toHaveLength(0);
  });

  describe('pagination', () => {
    it('shows pagination when configs length exceeds limit', () => {
      const manyConfigs = Array(MAX_LIST_COUNT + 1)
        .fill()
        .map((_, i) => ({
          name: `agent-${i}`,
          path: `path/to/agent-${i}`,
          webPath: `/agent-${i}`,
        }));

      createComponent({ props: { configs: manyConfigs } });

      expect(findPagination().exists()).toBe(true);
    });

    it('does not show pagination when maxConfigs is set', () => {
      createComponent({ props: { maxConfigs: 5 } });

      expect(wrapper.findComponent(GlPagination).exists()).toBe(false);
    });
  });

  describe('register functionality', () => {
    it('emits registerAgent event with correct agent name', async () => {
      createComponent();

      const firstButton = findAllButtons().at(0);
      await firstButton.vm.$emit('click');

      expect(wrapper.emitted('registerAgent')[0]).toEqual(['agent-1']);
    });
  });

  describe('terraform banner', () => {
    it('displays a banner when number of configs exceeds MAX_LIST_COUNT', () => {
      const manyConfigs = Array(MAX_LIST_COUNT)
        .fill()
        .map((_, i) => ({
          name: `agent-${i}`,
          path: `path/to/agent-${i}`,
          webPath: `/agent-${i}`,
        }));
      createComponent({ props: { configs: manyConfigs } });

      expect(findAlert().text()).toBe('To manage more agents, use Terraform.');
    });

    it('displays additional warning when number of configs exceeds MAX_CONFIGS_SHOWN', () => {
      const manyConfigs = Array(MAX_CONFIGS_SHOWN)
        .fill()
        .map((_, i) => ({
          name: `agent-${i}`,
          path: `path/to/agent-${i}`,
          webPath: `/agent-${i}`,
        }));
      createComponent({ props: { configs: manyConfigs } });

      expect(findAlert().text()).toBe(
        'We only support 100 agents on the UI. To manage more agents, use Terraform.',
      );
    });
  });
});
