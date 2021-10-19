import { mount } from '@vue/test-utils';
import App from '~/work_items/components/app.vue';
import WorkItemsRoot from '~/work_items/pages/work_item_root.vue';
import { createRouter } from '~/work_items/router';

describe('Work items router', () => {
  let wrapper;

  const createComponent = async (routeArg) => {
    const router = createRouter('/work_item');
    if (routeArg !== undefined) {
      await router.push(routeArg);
    }

    wrapper = mount(App, {
      router,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    window.location.hash = '';
  });

  it('renders work item on `/1` route', async () => {
    await createComponent('/1');

    expect(wrapper.find(WorkItemsRoot).exists()).toBe(true);
  });
});
