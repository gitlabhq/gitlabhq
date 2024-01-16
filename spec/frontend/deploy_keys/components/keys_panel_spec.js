import { mount } from '@vue/test-utils';
import enabledKeys from 'test_fixtures/deploy_keys/enabled_keys.json';
import deployKeysPanel from '~/deploy_keys/components/keys_panel.vue';
import { mapDeployKey } from '~/deploy_keys/graphql/resolvers';

const keys = enabledKeys.keys.map(mapDeployKey);

describe('Deploy keys panel', () => {
  let wrapper;

  const findTableRowHeader = () => wrapper.find('.table-row-header');

  const mountComponent = (props) => {
    wrapper = mount(deployKeysPanel, {
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
    expect(wrapper.findAll('.deploy-key').length).toBe(keys.length);
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

    expect(wrapper.find('.gl-new-card-empty').exists()).toBe(true);

    expect(wrapper.find('.gl-new-card-empty').text().trim()).toBe(
      'No deploy keys found, start by adding a new one above.',
    );
  });

  it('renders no table header if keys are empty', () => {
    mountComponent({ keys: [] });
    expect(findTableRowHeader().exists()).toBe(false);
  });
});
