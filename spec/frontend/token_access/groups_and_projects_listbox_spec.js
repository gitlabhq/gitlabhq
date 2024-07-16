import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import GroupsAndProjectsListbox from '~/token_access/components/groups_and_projects_listbox.vue';
import getGroupsAndProjectsQuery from '~/token_access/graphql/queries/get_groups_and_projects.query.graphql';
import { getGroupsAndProjectsResponse } from './mock_data';

const placeholder = 'Pick a group or project';

Vue.use(VueApollo);

describe('GroupsAndProjectsListbox component', () => {
  let wrapper;

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const openListbox = () => findListbox().vm.$emit('shown');
  const findListboxItems = () => wrapper.findAllComponents(GlListboxItem);

  const createComponent = ({
    mountFn = mountExtended,
    requestHandlers = [
      [
        getGroupsAndProjectsQuery,
        jest.fn().mockImplementation(({ search }) => {
          if (search !== '') {
            return {
              data: {
                groups: {
                  nodes: [getGroupsAndProjectsResponse.data.groups.nodes[0]],
                },
                projects: {
                  nodes: [getGroupsAndProjectsResponse.data.projects.nodes[0]],
                },
              },
            };
          }
          return getGroupsAndProjectsResponse;
        }),
      ],
    ],
    value = '',
  } = {}) => {
    wrapper = mountFn(GroupsAndProjectsListbox, {
      apolloProvider: createMockApollo(requestHandlers),
      propsData: {
        value,
        placeholder,
      },
    });
  };

  beforeEach(async () => {
    createComponent();

    await waitForPromises();
  });

  it('displays a listbox', () => {
    expect(findListbox().exists()).toBe(true);
  });

  it('displays the placeholder as the toggle text', () => {
    expect(findListbox().props('toggleText')).toBe(placeholder);
  });

  it('lists groups and projects', () => {
    expect(findListbox().props('items')).toMatchObject([
      { text: 'Groups', options: getGroupsAndProjectsResponse.data.groups.nodes },
      { text: 'Projects', options: getGroupsAndProjectsResponse.data.projects.nodes },
    ]);
  });

  it('searches for groups and projects', async () => {
    expect(findListbox().props('items')[0].options).toHaveLength(
      getGroupsAndProjectsResponse.data.groups.nodes.length,
    );
    expect(findListbox().props('items')[1].options).toHaveLength(
      getGroupsAndProjectsResponse.data.projects.nodes.length,
    );

    openListbox();
    findListbox().vm.$emit('search', 'gitlab');

    await waitForPromises();

    expect(findListbox().props('items')[0].options).toHaveLength(1);
    expect(findListbox().props('items')[1].options).toHaveLength(1);
  });

  it('emits select event with the fullPath when an item is selected', () => {
    openListbox();
    findListboxItems().at(0).trigger('click');

    expect(wrapper.emitted('select')[0][0]).toEqual(
      getGroupsAndProjectsResponse.data.groups.nodes[0].fullPath,
    );
  });
});
