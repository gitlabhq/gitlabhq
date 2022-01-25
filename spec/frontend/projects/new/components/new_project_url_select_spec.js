import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import eventHub from '~/projects/new/event_hub';
import NewProjectUrlSelect from '~/projects/new/components/new_project_url_select.vue';
import searchQuery from '~/projects/new/queries/search_namespaces_where_user_can_create_projects.query.graphql';

describe('NewProjectUrlSelect component', () => {
  let wrapper;

  const data = {
    currentUser: {
      id: 'user-1',
      groups: {
        nodes: [
          {
            id: 'gid://gitlab/Group/26',
            fullPath: 'flightjs',
            name: 'Flight JS',
            visibility: 'public',
            webUrl: 'http://127.0.0.1:3000/flightjs',
          },
          {
            id: 'gid://gitlab/Group/28',
            fullPath: 'h5bp',
            name: 'H5BP',
            visibility: 'public',
            webUrl: 'http://127.0.0.1:3000/h5bp',
          },
          {
            id: 'gid://gitlab/Group/30',
            fullPath: 'h5bp/subgroup',
            name: 'H5BP Subgroup',
            visibility: 'private',
            webUrl: 'http://127.0.0.1:3000/h5bp/subgroup',
          },
        ],
      },
      namespace: {
        id: 'gid://gitlab/Namespace/1',
        fullPath: 'root',
      },
    },
  };

  Vue.use(VueApollo);

  const defaultProvide = {
    namespaceFullPath: 'h5bp',
    namespaceId: '28',
    rootUrl: 'https://gitlab.com/',
    trackLabel: 'blank_project',
    userNamespaceFullPath: 'root',
    userNamespaceId: '1',
  };

  let mockQueryResponse;

  const mountComponent = ({
    search = '',
    queryResponse = data,
    provide = defaultProvide,
    mountFn = shallowMount,
  } = {}) => {
    mockQueryResponse = jest.fn().mockResolvedValue({ data: queryResponse });
    const requestHandlers = [[searchQuery, mockQueryResponse]];
    const apolloProvider = createMockApollo(requestHandlers);

    return mountFn(NewProjectUrlSelect, {
      apolloProvider,
      provide,
      data() {
        return {
          search,
        };
      },
    });
  };

  const findButtonLabel = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findInput = () => wrapper.findComponent(GlSearchBoxByType);
  const findHiddenInput = () => wrapper.find('[name="project[namespace_id]"]');

  const clickDropdownItem = async () => {
    wrapper.findComponent(GlDropdownItem).vm.$emit('click');
    await nextTick();
  };

  const showDropdown = async () => {
    findDropdown().vm.$emit('shown');
    await wrapper.vm.$apollo.queries.currentUser.refetch();
    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the root url as a label', () => {
    wrapper = mountComponent();

    expect(findButtonLabel().text()).toBe(defaultProvide.rootUrl);
    expect(findButtonLabel().props('label')).toBe(true);
  });

  describe('when namespaceId is provided', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('renders a dropdown with the given namespace full path as the text', () => {
      expect(findDropdown().props('text')).toBe(defaultProvide.namespaceFullPath);
    });

    it('renders a dropdown with the given namespace id in the hidden input', () => {
      expect(findHiddenInput().attributes('value')).toBe(defaultProvide.namespaceId);
    });
  });

  describe('when namespaceId is not provided', () => {
    const provide = {
      ...defaultProvide,
      namespaceFullPath: undefined,
      namespaceId: undefined,
    };

    beforeEach(() => {
      wrapper = mountComponent({ provide });
    });

    it("renders a dropdown with the user's namespace full path as the text", () => {
      expect(findDropdown().props('text')).toBe(defaultProvide.userNamespaceFullPath);
    });

    it("renders a dropdown with the user's namespace id in the hidden input", () => {
      expect(findHiddenInput().attributes('value')).toBe(defaultProvide.userNamespaceId);
    });
  });

  it('focuses on the input when the dropdown is opened', async () => {
    wrapper = mountComponent({ mountFn: mount });

    const spy = jest.spyOn(findInput().vm, 'focusInput');

    await showDropdown();

    expect(spy).toHaveBeenCalledTimes(1);
  });

  it('renders expected dropdown items', async () => {
    wrapper = mountComponent({ mountFn: mount });

    await showDropdown();

    const listItems = wrapper.findAll('li');

    expect(listItems).toHaveLength(6);
    expect(listItems.at(0).findComponent(GlDropdownSectionHeader).text()).toBe('Groups');
    expect(listItems.at(1).text()).toBe(data.currentUser.groups.nodes[0].fullPath);
    expect(listItems.at(2).text()).toBe(data.currentUser.groups.nodes[1].fullPath);
    expect(listItems.at(3).text()).toBe(data.currentUser.groups.nodes[2].fullPath);
    expect(listItems.at(4).findComponent(GlDropdownSectionHeader).text()).toBe('Users');
    expect(listItems.at(5).text()).toBe(data.currentUser.namespace.fullPath);
  });

  describe('query fetching', () => {
    describe('on component mount', () => {
      it('does not fetch query', () => {
        wrapper = mountComponent({ mountFn: mount });

        expect(mockQueryResponse).not.toHaveBeenCalled();
      });
    });

    describe('on dropdown shown', () => {
      it('fetches query', async () => {
        wrapper = mountComponent({ mountFn: mount });

        await showDropdown();

        expect(mockQueryResponse).toHaveBeenCalled();
      });
    });
  });

  describe('when selecting from a group template', () => {
    const { fullPath, id } = data.currentUser.groups.nodes[1];

    beforeEach(async () => {
      wrapper = mountComponent({ mountFn: mount });

      // Show dropdown to fetch projects
      await showDropdown();

      eventHub.$emit('select-template', getIdFromGraphQLId(id), fullPath);
    });

    it('filters the dropdown items to the selected group and children', async () => {
      const listItems = wrapper.findAll('li');

      expect(listItems).toHaveLength(3);
      expect(listItems.at(0).findComponent(GlDropdownSectionHeader).text()).toBe('Groups');
      expect(listItems.at(1).text()).toBe(data.currentUser.groups.nodes[1].fullPath);
      expect(listItems.at(2).text()).toBe(data.currentUser.groups.nodes[2].fullPath);
    });

    it('sets the selection to the group', async () => {
      expect(findDropdown().props('text')).toBe(fullPath);
    });
  });

  it('renders `No matches found` when there are no matching dropdown items', async () => {
    const queryResponse = {
      currentUser: {
        id: 'user-1',
        groups: {
          nodes: [],
        },
        namespace: {
          id: 'gid://gitlab/Namespace/1',
          fullPath: 'root',
        },
      },
    };

    wrapper = mountComponent({ search: 'no matches', queryResponse, mountFn: mount });
    await waitForPromises();

    expect(wrapper.find('li').text()).toBe('No matches found');
  });

  it('emits `update-visibility` event to update the visibility radio options', async () => {
    wrapper = mountComponent({ mountFn: mount });

    const spy = jest.spyOn(eventHub, '$emit');

    // Show dropdown to fetch projects
    await showDropdown();

    await clickDropdownItem();

    const namespace = data.currentUser.groups.nodes[0];

    expect(spy).toHaveBeenCalledWith('update-visibility', {
      name: namespace.name,
      visibility: namespace.visibility,
      showPath: namespace.webUrl,
      editPath: `${namespace.webUrl}/-/edit`,
    });
  });

  it('updates hidden input with selected namespace', async () => {
    wrapper = mountComponent({ mountFn: mount });

    // Show dropdown to fetch projects
    await showDropdown();

    await clickDropdownItem();

    expect(findHiddenInput().attributes('value')).toBe(
      getIdFromGraphQLId(data.currentUser.groups.nodes[0].id).toString(),
    );
  });

  it('tracks clicking on the dropdown', () => {
    wrapper = mountComponent();

    const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

    findDropdown().vm.$emit('show');

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'activate_form_input', {
      label: defaultProvide.trackLabel,
      property: 'project_path',
    });

    unmockTracking();
  });
});
