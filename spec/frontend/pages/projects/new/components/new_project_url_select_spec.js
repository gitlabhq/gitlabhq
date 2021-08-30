import { GlButton, GlDropdown, GlDropdownItem, GlDropdownSectionHeader } from '@gitlab/ui';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import NewProjectUrlSelect from '~/pages/projects/new/components/new_project_url_select.vue';
import searchQuery from '~/pages/projects/new/queries/search_namespaces_where_user_can_create_projects.query.graphql';

describe('NewProjectUrlSelect component', () => {
  let wrapper;

  const data = {
    currentUser: {
      groups: {
        nodes: [
          {
            id: 'gid://gitlab/Group/26',
            fullPath: 'flightjs',
          },
          {
            id: 'gid://gitlab/Group/28',
            fullPath: 'h5bp',
          },
        ],
      },
      namespace: {
        id: 'gid://gitlab/Namespace/1',
        fullPath: 'root',
      },
    },
  };

  const localVue = createLocalVue();
  localVue.use(VueApollo);

  const requestHandlers = [[searchQuery, jest.fn().mockResolvedValue({ data })]];
  const apolloProvider = createMockApollo(requestHandlers);

  const provide = {
    namespaceFullPath: 'h5bp',
    namespaceId: '28',
    rootUrl: 'https://gitlab.com/',
    trackLabel: 'blank_project',
  };

  const mountComponent = ({ mountFn = shallowMount } = {}) =>
    mountFn(NewProjectUrlSelect, { localVue, apolloProvider, provide });

  const findButtonLabel = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findHiddenInput = () => wrapper.find('input');

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the root url as a label', () => {
    wrapper = mountComponent();

    expect(findButtonLabel().text()).toBe(provide.rootUrl);
    expect(findButtonLabel().props('label')).toBe(true);
  });

  it('renders a dropdown with the initial namespace full path as the text', () => {
    wrapper = mountComponent();

    expect(findDropdown().props('text')).toBe(provide.namespaceFullPath);
  });

  it('renders a dropdown with the initial namespace id in the hidden input', () => {
    wrapper = mountComponent();

    expect(findHiddenInput().attributes('value')).toBe(provide.namespaceId);
  });

  it('renders expected dropdown items', async () => {
    wrapper = mountComponent({ mountFn: mount });

    jest.runOnlyPendingTimers();
    await wrapper.vm.$nextTick();

    const listItems = wrapper.findAll('li');

    expect(listItems.at(0).findComponent(GlDropdownSectionHeader).text()).toBe('Groups');
    expect(listItems.at(1).text()).toBe(data.currentUser.groups.nodes[0].fullPath);
    expect(listItems.at(2).text()).toBe(data.currentUser.groups.nodes[1].fullPath);
    expect(listItems.at(3).findComponent(GlDropdownSectionHeader).text()).toBe('Users');
    expect(listItems.at(4).text()).toBe(data.currentUser.namespace.fullPath);
  });

  it('updates hidden input with selected namespace', async () => {
    wrapper = mountComponent();

    jest.runOnlyPendingTimers();
    await wrapper.vm.$nextTick();

    wrapper.findComponent(GlDropdownItem).vm.$emit('click');

    await wrapper.vm.$nextTick();

    expect(findHiddenInput().attributes()).toMatchObject({
      name: 'project[namespace_id]',
      value: getIdFromGraphQLId(data.currentUser.groups.nodes[0].id).toString(),
    });
  });

  it('tracks clicking on the dropdown', () => {
    wrapper = mountComponent();

    const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

    findDropdown().vm.$emit('show');

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'activate_form_input', {
      label: provide.trackLabel,
      property: 'project_path',
    });

    unmockTracking();
  });
});
