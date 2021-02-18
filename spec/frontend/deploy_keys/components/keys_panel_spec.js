import { mount } from '@vue/test-utils';
import deployKeysPanel from '~/deploy_keys/components/keys_panel.vue';
import DeployKeysStore from '~/deploy_keys/store';

describe('Deploy keys panel', () => {
  const data = getJSONFixture('deploy_keys/keys.json');
  let wrapper;

  const findTableRowHeader = () => wrapper.find('.table-row-header');

  const mountComponent = (props) => {
    const store = new DeployKeysStore();
    store.keys = data;
    wrapper = mount(deployKeysPanel, {
      propsData: {
        title: 'test',
        keys: data.enabled_keys,
        showHelpBox: true,
        store,
        endpoint: 'https://test.host/dummy/endpoint',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders list of keys', () => {
    mountComponent();
    expect(wrapper.findAll('.deploy-key').length).toBe(wrapper.vm.keys.length);
  });

  it('renders table header', () => {
    mountComponent();
    const tableHeader = findTableRowHeader();

    expect(tableHeader).toExist();
    expect(tableHeader.text()).toContain('Deploy key');
    expect(tableHeader.text()).toContain('Project usage');
    expect(tableHeader.text()).toContain('Created');
  });

  it('renders help box if keys are empty', () => {
    mountComponent({ keys: [] });

    expect(wrapper.find('.settings-message').exists()).toBe(true);

    expect(wrapper.find('.settings-message').text().trim()).toBe(
      'No deploy keys found. Create one with the form above.',
    );
  });

  it('renders no table header if keys are empty', () => {
    mountComponent({ keys: [] });
    expect(findTableRowHeader().exists()).toBe(false);
  });
});
