import { shallowMount } from '@vue/test-utils';
import CreateWorkItemPage from '~/work_items/pages/create_work_item.vue';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility');

describe('Create work item page component', () => {
  let wrapper;

  const createComponent = ($router = undefined) => {
    wrapper = shallowMount(CreateWorkItemPage, {
      mocks: {
        $router,
      },
      provide: {
        fullPath: 'gitlab-org',
        isGroup: true,
      },
    });
  };

  it('visits work item detail page after create if router is not present', () => {
    createComponent();

    wrapper
      .findComponent(CreateWorkItem)
      .vm.$emit('workItemCreated', { webUrl: '/work_items/1234' });

    expect(visitUrl).toHaveBeenCalledWith('/work_items/1234');
  });

  it('calls router.push after create if router is present', () => {
    const pushMock = jest.fn();
    createComponent({ push: pushMock });

    wrapper
      .findComponent(CreateWorkItem)
      .vm.$emit('workItemCreated', { webUrl: '/work_items/1234', iid: '1234' });

    expect(pushMock).toHaveBeenCalledWith({ name: 'workItem', params: { iid: '1234' } });
  });
});
