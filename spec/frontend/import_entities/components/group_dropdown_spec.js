import { GlSearchBoxByType, GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import GroupDropdown from '~/import_entities/components/group_dropdown.vue';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import searchNamespacesWhereUserCanImportProjectsQuery from '~/import_entities/import_projects/graphql/queries/search_namespaces_where_user_can_import_projects.query.graphql';

Vue.use(VueApollo);

const makeGroupMock = (fullPath) => ({
  id: `gid://gitlab/Group/${fullPath}`,
  fullPath,
  name: fullPath,
  visibility: 'public',
  webUrl: `http://gdk.test:3000/groups/${fullPath}`,
  __typename: 'Group',
});

const AVAILABLE_NAMESPACES = [
  makeGroupMock('match1'),
  makeGroupMock('unrelated'),
  makeGroupMock('match2'),
];

const SEARCH_NAMESPACES_MOCK = Promise.resolve({
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      groups: {
        nodes: AVAILABLE_NAMESPACES,
        __typename: 'GroupConnection',
      },
      namespace: {
        id: 'gid://gitlab/Namespaces::UserNamespace/1',
        fullPath: 'root',
        __typename: 'Namespace',
      },
      __typename: 'UserCore',
    },
  },
});

describe('Import entities group dropdown component', () => {
  let wrapper;
  let namespacesTracker;

  const createComponent = (propsData) => {
    const apolloProvider = createMockApollo([
      [searchNamespacesWhereUserCanImportProjectsQuery, () => SEARCH_NAMESPACES_MOCK],
    ]);

    namespacesTracker = jest.fn();

    wrapper = shallowMount(GroupDropdown, {
      apolloProvider,
      scopedSlots: {
        default: namespacesTracker,
      },
      stubs: { GlDropdown },
      propsData,
    });
  };

  it('passes namespaces from graphql query to default slot', async () => {
    createComponent();
    jest.advanceTimersByTime(DEBOUNCE_DELAY);
    await nextTick();
    await waitForPromises();
    await nextTick();

    expect(namespacesTracker).toHaveBeenCalledWith({ namespaces: AVAILABLE_NAMESPACES });
  });

  it('filters namespaces based on user input', async () => {
    createComponent();

    namespacesTracker.mockReset();
    wrapper.findComponent(GlSearchBoxByType).vm.$emit('input', 'match');
    jest.advanceTimersByTime(DEBOUNCE_DELAY);
    await nextTick();
    await waitForPromises();
    await nextTick();

    expect(namespacesTracker).toHaveBeenCalledWith({
      namespaces: [
        expect.objectContaining({ fullPath: 'match1' }),
        expect.objectContaining({ fullPath: 'match2' }),
      ],
    });
  });
});
