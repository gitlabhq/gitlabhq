import { GlCollapsibleListbox } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import ImportTargetDropdown from '~/import_entities/components/import_target_dropdown.vue';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import searchNamespacesWhereUserCanImportProjectsQuery from '~/import_entities/import_projects/graphql/queries/search_namespaces_where_user_can_import_projects.query.graphql';

import { mockAvailableNamespaces, mockNamespacesResponse, mockUserNamespace } from '../mock_data';

Vue.use(VueApollo);

describe('ImportTargetDropdown', () => {
  let wrapper;

  const defaultProps = {
    selected: mockUserNamespace,
  };

  const createComponent = ({ props = {} } = {}) => {
    const apolloProvider = createMockApollo([
      [
        searchNamespacesWhereUserCanImportProjectsQuery,
        jest.fn().mockResolvedValue(mockNamespacesResponse),
      ],
    ]);

    wrapper = shallowMount(ImportTargetDropdown, {
      apolloProvider,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxFirstGroupItems = () => findListbox().props('items')[0].options;
  const findListboxGroupsItems = () => findListbox().props('items')[1].options;

  const waitForQuery = async () => {
    jest.advanceTimersByTime(DEBOUNCE_DELAY);
    await waitForPromises();
  };

  it('renders listbox', () => {
    createComponent();

    expect(findListbox().exists()).toBe(true);
  });

  it('truncates "toggle-text" when "selected" is too long', () => {
    const mockSelected = 'a-group-path-that-is-longer-than-24-characters';

    createComponent({
      props: { selected: mockSelected },
    });

    expect(findListbox().props('toggleText')).toBe('a-group-path-that-is-lo…');
  });

  describe('when used on group import', () => {
    beforeEach(() => {
      createComponent();
    });

    it('adds "No parent" in "Parent" group', () => {
      expect(findListboxFirstGroupItems()).toEqual([{ text: 'No parent', value: '' }]);
    });

    it('emits "select" event with { fullPath: "", id: null } when "No parent" is selected', () => {
      findListbox().vm.$emit('select', '');

      expect(wrapper.emitted('select')[0]).toEqual([{ fullPath: '', id: null }]);
    });

    it('emits "select" event with { fullPath, id } when a group is selected', async () => {
      await waitForQuery();

      const mockGroupPath = 'match1';

      findListbox().vm.$emit('select', mockGroupPath);

      expect(wrapper.emitted('select')[0]).toEqual([
        { fullPath: mockGroupPath, id: `gid://gitlab/Group/${mockGroupPath}` },
      ]);
    });
  });

  describe('when used on project import', () => {
    beforeEach(() => {
      createComponent({
        props: { userNamespace: mockUserNamespace },
      });
    });

    it('passes userNamespace as "Users" group item', () => {
      expect(findListboxFirstGroupItems()).toEqual([
        { text: mockUserNamespace, value: mockUserNamespace },
      ]);
    });

    it('emits "select" event with path as value', () => {
      const mockProjectPath = 'mock-project';

      findListbox().vm.$emit('select', mockProjectPath);

      expect(wrapper.emitted('select')[0]).toEqual([mockProjectPath]);
    });
  });

  it('passes namespaces from GraphQL as "Groups" group item', async () => {
    createComponent();

    await waitForQuery();

    expect(findListboxGroupsItems()).toEqual(
      mockAvailableNamespaces.map((namespace) => ({
        text: namespace.fullPath,
        value: namespace.fullPath,
      })),
    );
  });

  it('filters namespaces based on user input', async () => {
    createComponent();

    findListbox().vm.$emit('search', 'match');

    await waitForQuery();

    expect(findListboxGroupsItems()).toEqual([
      { text: 'match1', value: 'match1' },
      { text: 'match2', value: 'match2' },
    ]);
  });
});
