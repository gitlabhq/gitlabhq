import { shallowMount } from '@vue/test-utils';
import CreateWorkItemPage from '~/work_items/pages/create_work_item.vue';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility');

describe('Create work item page component', () => {
  let wrapper;

  it('visits work item detail page after create', () => {
    wrapper = shallowMount(CreateWorkItemPage, {
      provide: {
        fullPath: 'gitlab-org',
        isGroup: true,
      },
    });

    wrapper
      .findComponent(CreateWorkItem)
      .vm.$emit('workItemCreated', { webUrl: '/work_items/1234' });

    expect(visitUrl).toHaveBeenCalledWith('/work_items/1234');
  });
});
