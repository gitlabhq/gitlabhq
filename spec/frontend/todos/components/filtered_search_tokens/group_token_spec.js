import { GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import searchTodosGroupsQuery from '~/todos/components/queries/search_todos_groups.query.graphql';
import GroupToken from '~/todos/components/filtered_search_tokens/group_token.vue';
import AsyncToken from '~/todos/components/filtered_search_tokens/async_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { stubComponent } from 'helpers/stub_component';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { todosGroupsResponse } from '../../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

const mockToken = {
  type: 'group',
  icon: 'group',
  title: 'Group',
  unique: true,
  token: GroupToken,
  operators: OPERATORS_IS,
};

const [firstGroup] = todosGroupsResponse.data.currentUser.groups.nodes;
const mockGroup = {
  id: String(getIdFromGraphQLId(firstGroup.id)),
  name: firstGroup.name,
  full_path: firstGroup.fullName,
};
const mockGroupInfoEndpoint = `/api/v4/groups/${mockGroup.id}`;

const searchTodosGroupsQuerySuccessHandler = jest.fn().mockResolvedValue(todosGroupsResponse);

describe('GroupToken', () => {
  let wrapper;
  let axiosMock;

  function createComponent({
    props = {},
    data = {},
    stubs = {},
    searchTodosGroupsQueryHandler = searchTodosGroupsQuerySuccessHandler,
  } = {}) {
    const mockApollo = createMockApollo();
    mockApollo.defaultClient.setRequestHandler(
      searchTodosGroupsQuery,
      searchTodosGroupsQueryHandler,
    );
    wrapper = mount(GroupToken, {
      apolloProvider: mockApollo,
      propsData: {
        config: mockToken,
        value: { data: '' },
        active: false,
        ...props,
      },
      data() {
        return data;
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: () => {},
        termsAsTokens: true,
      },
      stubs: { Portal: true, ...stubs },
    });
  }

  const findBaseToken = () => wrapper.findComponent(BaseToken);
  const findGlFilteredSearchTokenSegments = () =>
    wrapper.findAllComponents(GlFilteredSearchTokenSegment);

  const triggerFetchSuggestions = (searchTerm = null) => {
    findBaseToken().vm.$emit('fetch-suggestions', searchTerm);
    return waitForPromises();
  };

  const itRendersToken = (group) => {
    const [tokenName, , tokenValue] = findGlFilteredSearchTokenSegments().wrappers;
    expect(tokenName.text()).toBe(mockToken.title);
    expect(tokenValue.text()).toBe(group.name);
  };

  beforeEach(() => {
    gon.api_version = 'v4';
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it("fetches the initially selected group's info if any, delaying the base token's rendering", async () => {
    axiosMock.onGet(mockGroupInfoEndpoint).reply(200, mockGroup);
    createComponent({
      props: { value: { data: mockGroup.id } },
      // Prevent the suggestions query from resolving to prevent false positives
      searchTodosGroupsQueryHandler: () => new Promise(),
    });

    expect(findBaseToken().exists()).toBe(false);

    await waitForPromises();

    expect(findBaseToken().exists()).toBe(true);
    itRendersToken(mockGroup);
  });

  it("creates an alert if it fails to fetch the initially selected group's info", async () => {
    axiosMock.onGet(mockGroupInfoEndpoint).reply(404);
    createComponent({ props: { value: { data: mockGroup.id } } });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'There was a problem fetching groups.',
      error: expect.any(Error),
    });
  });

  it('starts fetching suggestions on mount', async () => {
    createComponent();
    await nextTick();

    expect(searchTodosGroupsQuerySuccessHandler).toHaveBeenCalled();
    expect(findBaseToken().props('suggestionsLoading')).toBe(true);

    await waitForPromises();

    expect(findBaseToken().props('suggestionsLoading')).toBe(false);
  });

  it('sets the loading state while fetching suggestions', async () => {
    createComponent();

    await waitForPromises();

    expect(findBaseToken().props('suggestionsLoading')).toBe(false);

    triggerFetchSuggestions('group');
    await nextTick();

    expect(findBaseToken().props('suggestionsLoading')).toBe(true);
  });

  it("renders the groups' full names in the suggestions list", () => {
    createComponent({
      stubs: {
        AsyncToken: stubComponent(AsyncToken, {
          data() {
            return {
              suggestions: [...todosGroupsResponse.data.currentUser.groups.nodes],
            };
          },
          template: `
          <div>
            <div v-for="suggestion in suggestions">
              <slot name="suggestion-display-name" :suggestion="suggestion"></slot>
            </div>
          </div>
        `,
        }),
      },
    });
    const suggestionTexts = wrapper
      .text()
      .split('\n')
      .map((text) => text.trim())
      .filter(Boolean);

    todosGroupsResponse.data.currentUser.groups.nodes.forEach((group, i) => {
      expect(suggestionTexts[i]).toBe(group.fullName);
    });
  });

  it("renders the selected group's token", async () => {
    const selectedGroup = todosGroupsResponse.data.currentUser.groups.nodes[0];
    createComponent({
      props: {
        value: { data: String(getIdFromGraphQLId(selectedGroup.id)) },
      },
    });
    await waitForPromises();

    itRendersToken(selectedGroup);
  });

  it("renders the selected group's token without prefix", async () => {
    const selectedGroup = todosGroupsResponse.data.currentUser.groups.nodes[0];
    createComponent({
      props: {
        value: { data: String(getIdFromGraphQLId(selectedGroup.id)) },
        config: {
          ...mockToken,
          skipIdPrefix: true,
        },
      },
    });
    await waitForPromises();

    itRendersToken(selectedGroup);
  });

  it('creates an alert if the query fails', async () => {
    createComponent({
      searchTodosGroupsQueryHandler: jest.fn().mockRejectedValue(),
    });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({ message: 'There was a problem fetching groups.' });
  });
});
