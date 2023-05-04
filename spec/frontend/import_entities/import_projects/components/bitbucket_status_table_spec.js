import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

import BitbucketStatusTable from '~/import_entities/import_projects/components/bitbucket_status_table.vue';
import ImportProjectsTable from '~/import_entities/import_projects/components/import_projects_table.vue';

const ImportProjectsTableStub = {
  name: 'ImportProjectsTable',
  template:
    '<div><slot name="incompatible-repos-warning"></slot><slot name="actions"></slot></div>',
};

describe('BitbucketStatusTable', () => {
  let wrapper;

  function createComponent(propsData, importProjectsTableStub = true, slots) {
    wrapper = shallowMount(BitbucketStatusTable, {
      propsData,
      stubs: {
        ImportProjectsTable: importProjectsTableStub,
      },
      slots,
    });
  }

  it('renders import table component', () => {
    createComponent({ providerTitle: 'Test' });
    expect(wrapper.findComponent(ImportProjectsTable).exists()).toBe(true);
  });

  it('passes alert in incompatible-repos-warning slot', () => {
    createComponent({ providerTitle: 'Test' }, ImportProjectsTableStub);
    expect(wrapper.findComponent(GlAlert).exists()).toBe(true);
  });

  it('passes actions slot to import project table component', () => {
    const actionsSlotContent = 'DEMO';
    createComponent({ providerTitle: 'Test' }, ImportProjectsTableStub, {
      actions: actionsSlotContent,
    });
    expect(wrapper.findComponent(ImportProjectsTable).text()).toBe(actionsSlotContent);
  });

  it('dismisses alert when requested', async () => {
    createComponent({ providerTitle: 'Test' }, ImportProjectsTableStub);
    wrapper.findComponent(GlAlert).vm.$emit('dismiss');
    await nextTick();

    expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
  });
});
