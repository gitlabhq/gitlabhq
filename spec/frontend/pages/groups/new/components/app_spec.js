import { shallowMount } from '@vue/test-utils';
import App from '~/pages/groups/new/components/app.vue';
import NewNamespacePage from '~/vue_shared/new_namespace/new_namespace_page.vue';

describe('App component', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(App, { propsData });
  };

  const findNewNamespacePage = () => wrapper.findComponent(NewNamespacePage);

  const findCreateGroupPanel = () =>
    findNewNamespacePage()
      .props('panels')
      .find((panel) => panel.name === 'create-group-pane');

  afterEach(() => {
    wrapper.destroy();
  });

  it('creates correct component for group creation', () => {
    createComponent();

    expect(findNewNamespacePage().props('initialBreadcrumbs')).toEqual([
      { href: '#', text: 'New group' },
    ]);
    expect(findCreateGroupPanel().title).toBe('Create group');
  });

  it('creates correct component for subgroup creation', () => {
    const props = { parentGroupName: 'parent', importExistingGroupPath: '/path' };

    createComponent(props);

    expect(findNewNamespacePage().props('initialBreadcrumbs')).toEqual([
      { href: '#', text: 'New group' },
    ]);
    expect(findCreateGroupPanel().title).toBe('Create subgroup');
    expect(findCreateGroupPanel().detailProps).toEqual(props);
  });
});
