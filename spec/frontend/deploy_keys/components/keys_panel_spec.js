import enabledKeys from 'test_fixtures/deploy_keys/enabled_keys.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import deployKeysPanel from '~/deploy_keys/components/keys_panel.vue';
import DeployKey from '~/deploy_keys/components/key.vue';
import { mapDeployKey } from '~/deploy_keys/graphql/resolvers';

const keys = enabledKeys.keys.map(mapDeployKey);

describe('Deploy keys panel', () => {
  let wrapper;

  const findTableRowHeader = () => wrapper.find('.table-row-header');
  const findEmptyState = () => wrapper.findByTestId('empty-state');

  const mountComponent = (props) => {
    wrapper = shallowMountExtended(deployKeysPanel, {
      propsData: {
        title: 'test',
        keys,
        showHelpBox: true,
        endpoint: 'https://test.host/dummy/endpoint',
        ...props,
      },
    });
  };

  it('renders list of keys', () => {
    mountComponent();
    expect(wrapper.findAllComponents(DeployKey)).toHaveLength(keys.length);
  });

  it('renders table header', () => {
    mountComponent();
    const tableHeader = findTableRowHeader();

    expect(tableHeader.exists()).toBe(true);
    expect(tableHeader.text()).toContain('Deploy key');
    expect(tableHeader.text()).toContain('Project usage');
    expect(tableHeader.text()).toContain('Created');
  });

  it('renders help box if keys are empty', () => {
    mountComponent({ keys: [] });
    expect(findEmptyState().exists()).toBe(true);
    expect(findEmptyState().text()).toBe('No deploy keys found, start by adding a new one above.');
  });

  it('renders help box with empty search text if keys are empty on search', () => {
    mountComponent({ keys: [], hasSearch: true });
    expect(findEmptyState().exists()).toBe(true);
    expect(findEmptyState().text()).toBe('No search results found.');
  });

  it('renders no table header if keys are empty', () => {
    mountComponent({ keys: [] });
    expect(findTableRowHeader().exists()).toBe(false);
  });
});
