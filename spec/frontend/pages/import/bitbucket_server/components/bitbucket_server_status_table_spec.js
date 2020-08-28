import { shallowMount } from '@vue/test-utils';

import { GlButton } from '@gitlab/ui';
import BitbucketServerStatusTable from '~/pages/import/bitbucket_server/status/components/bitbucket_server_status_table.vue';
import BitbucketStatusTable from '~/import_projects/components/bitbucket_status_table.vue';

const BitbucketStatusTableStub = {
  name: 'BitbucketStatusTable',
  template: '<div><slot name="actions"></slot></div>',
};

describe('BitbucketServerStatusTable', () => {
  let wrapper;

  const findReconfigureButton = () =>
    wrapper
      .findAll(GlButton)
      .filter(w => w.props().variant === 'info')
      .at(0);

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  function createComponent(bitbucketStatusTableStub = true) {
    wrapper = shallowMount(BitbucketServerStatusTable, {
      propsData: { providerTitle: 'Test', reconfigurePath: '/reconfigure' },
      stubs: {
        BitbucketStatusTable: bitbucketStatusTableStub,
      },
    });
  }

  it('renders bitbucket status table component', () => {
    createComponent();
    expect(wrapper.find(BitbucketStatusTable).exists()).toBe(true);
  });

  it('renders Reconfigure button', async () => {
    createComponent(BitbucketStatusTableStub);
    expect(findReconfigureButton().attributes().href).toBe('/reconfigure');
    expect(findReconfigureButton().text()).toBe('Reconfigure');
  });
});
