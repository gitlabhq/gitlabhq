import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import BitbucketStatusTable from '~/import_entities/import_projects/components/bitbucket_status_table.vue';
import BitbucketServerStatusTable from '~/pages/import/bitbucket_server/status/components/bitbucket_server_status_table.vue';

const BitbucketStatusTableStub = {
  name: 'BitbucketStatusTable',
  template: '<div><slot name="actions"></slot></div>',
};

describe('BitbucketServerStatusTable', () => {
  let wrapper;

  const findReconfigureButton = () => wrapper.findComponent(GlButton);

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
    expect(wrapper.findComponent(BitbucketStatusTable).exists()).toBe(true);
  });

  it('renders Reconfigure button', () => {
    createComponent(BitbucketStatusTableStub);
    expect(findReconfigureButton().attributes().href).toBe('/reconfigure');
    expect(findReconfigureButton().text()).toBe('Reconfigure');
  });
});
