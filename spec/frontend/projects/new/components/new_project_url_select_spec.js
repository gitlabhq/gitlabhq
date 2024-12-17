import {
  GlButton,
  GlCollapsibleListbox,
  GlListboxItem,
  GlTruncate,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { stubComponent } from 'helpers/stub_component';
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
    userNamespaceId: '1',
    inputId: 'input_id',
    inputName: 'input_name',
  };

  const dropdownPlaceholderClass = '!gl-text-subtle';

  let mockQueryResponse;
  let focusInputSpy;

  const mountComponent = ({
    search = '',
    queryResponse = data,
    provide = defaultProvide,
    mountFn = shallowMount,
  } = {}) => {
    mockQueryResponse = jest.fn().mockResolvedValue({ data: queryResponse });
    const requestHandlers = [[searchQuery, mockQueryResponse]];
    const apolloProvider = createMockApollo(requestHandlers);
    focusInputSpy = jest.fn();

    return mountFn(NewProjectUrlSelect, {
      apolloProvider,
      provide,
      data() {
        return {
          search,
        };
      },
      stubs: {
        GlSearchBoxByType: stubComponent(GlSearchBoxByType, {
          methods: { focusInput: focusInputSpy },
        }),
      },
    });
  };

  const findButtonLabel = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSelectedPath = () => wrapper.findComponent(GlTruncate);
  const findHiddenNamespaceInput = () => wrapper.find(`[name="${defaultProvide.inputName}`);
  const findAllListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findToggleButton = () => findDropdown().findComponent(GlButton);

  const findHiddenSelectedNamespaceInput = () =>
    wrapper.find('[name="project[selected_namespace_id]"]');

  const clickDropdownItem = async () => {
    await findAllListboxItems().at(0).trigger('click');
  };

  const showDropdown = async () => {
    findDropdown().vm.$emit('shown');
    await wrapper.vm.$apollo.queries.currentUser.refetch();
    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  it('renders the root url as a label', () => {
    wrapper = mountComponent();

    expect(findButtonLabel().text()).toBe(defaultProvide.rootUrl);
    expect(findButtonLabel().props('label')).toBe(true);
  });

  describe('when namespaceId is provided', () => {
    beforeEach(() => {
      wrapper = mountComponent({ mountFn: mount });
    });

    it('renders a dropdown with the given namespace full path as the text', () => {
      expect(findSelectedPath().props('text')).toBe(defaultProvide.namespaceFullPath);
    });

    it('renders a dropdown without the class', () => {
      expect(findToggleButton().classes()).not.toContain(dropdownPlaceholderClass);
    });

    it('renders a hidden input with the given namespace id', () => {
      expect(findHiddenNamespaceInput().attributes('value')).toBe(defaultProvide.namespaceId);
    });

    it('renders a hidden input with the selected namespace id', () => {
      expect(findHiddenSelectedNamespaceInput().attributes('value')).toBe(
        defaultProvide.namespaceId,
      );
    });
  });

  describe('when namespaceId is not provided', () => {
    const provide = {
      ...defaultProvide,
      namespaceFullPath: undefined,
      namespaceId: undefined,
    };

    beforeEach(() => {
      wrapper = mountComponent({ provide, mountFn: mount });
    });

    it("renders a dropdown with the user's namespace full path as the text", () => {
      expect(findSelectedPath().props('text')).toBe('Pick a group or namespace');
    });

    it('renders a dropdown with the class', () => {
      expect(findToggleButton().classes()).toContain(dropdownPlaceholderClass);
    });

    it("renders a hidden input with the user's namespace id", () => {
      expect(findHiddenNamespaceInput().attributes('value')).toBe(defaultProvide.userNamespaceId);
      expect(findHiddenNamespaceInput().attributes('name')).toBe(defaultProvide.inputName);
      expect(findHiddenNamespaceInput().attributes('id')).toBe(defaultProvide.inputId);
    });

    it('renders a hidden input with the selected namespace id', () => {
      expect(findHiddenSelectedNamespaceInput().attributes('value')).toBe(undefined);
    });
  });

  it('renders expected dropdown items', async () => {
    wrapper = mountComponent({ mountFn: mount });

    await showDropdown();

    const { fullPath: text, id: value } = data.currentUser.namespace;
    const userOptions = [{ text, value }];
    const groupOptions = data.currentUser.groups.nodes.map((node) => ({
      text: node.fullPath,
      value: node.id,
    }));

    expect(findDropdown().props('items')).toEqual([
      { text: 'Groups', options: groupOptions },
      { text: 'Users', options: userOptions },
    ]);
  });

  it('does not render users section when user namespace id is not provided', async () => {
    wrapper = mountComponent({
      mountFn: mount,
      provide: { ...defaultProvide, userNamespaceId: null },
    });

    await showDropdown();

    const groupOptions = data.currentUser.groups.nodes.map((node) => ({
      text: node.fullPath,
      value: node.id,
    }));

    expect(findDropdown().props('items')).toEqual([{ text: 'Groups', options: groupOptions }]);
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

    it('filters the dropdown items to the selected group and children', () => {
      const filteredgroupOptions = data.currentUser.groups.nodes.filter((group) =>
        group.fullPath.startsWith(fullPath),
      );
      const groupOptions = filteredgroupOptions.map((node) => ({
        text: node.fullPath,
        value: node.id,
      }));

      expect(findDropdown().props('items')).toEqual([{ text: 'Groups', options: groupOptions }]);
    });

    it('sets the selection to the group', () => {
      expect(findSelectedPath().props('text')).toBe(fullPath);
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

    expect(wrapper.find('[data-testid="listbox-no-results-text"]').text()).toBe('No matches found');
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

    expect(findHiddenNamespaceInput().attributes('value')).toBe(
      getIdFromGraphQLId(data.currentUser.groups.nodes[0].id).toString(),
    );
  });

  it('tracks clicking on the dropdown when trackLabel is provided', () => {
    wrapper = mountComponent();

    const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

    findDropdown().vm.$emit('show');

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'activate_form_input', {
      label: defaultProvide.trackLabel,
      property: 'project_path',
    });

    unmockTracking();
  });

  it('does not track clicking on the dropdown when trackLabel is not provided', () => {
    wrapper = mountComponent({ provide: { ...defaultProvide, trackLabel: null } });

    const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

    findDropdown().vm.$emit('show');

    expect(trackingSpy).not.toHaveBeenCalled();

    unmockTracking();
  });
});
