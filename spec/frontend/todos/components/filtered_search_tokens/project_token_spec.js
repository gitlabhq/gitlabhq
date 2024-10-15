import { GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import searchTodosProjectsQuery from '~/todos/components/queries/search_todos_projects.query.graphql';
import ProjectToken from '~/todos/components/filtered_search_tokens/project_token.vue';
import AsyncToken from '~/todos/components/filtered_search_tokens/async_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { stubComponent } from 'helpers/stub_component';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { todosProjectsResponse } from '../../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

const mockToken = {
  type: 'project',
  icon: 'project',
  title: 'Project',
  unique: true,
  token: ProjectToken,
  operators: OPERATORS_IS,
};

const [firstProject] = todosProjectsResponse.data.projects.nodes;
const mockProject = {
  id: String(getIdFromGraphQLId(firstProject.id)),
  name: firstProject.name,
  full_path: firstProject.fullName,
};
const mockProjectInfoEndpoint = `/api/v4/projects/${mockProject.id}`;

const searchTodosProjectsQuerySuccessHandler = jest.fn().mockResolvedValue(todosProjectsResponse);

describe('ProjectToken', () => {
  let wrapper;
  let axiosMock;

  function createComponent({
    props = {},
    data = {},
    stubs = {},
    searchTodosProjectsQueryHandler = searchTodosProjectsQuerySuccessHandler,
  } = {}) {
    const mockApollo = createMockApollo();
    mockApollo.defaultClient.setRequestHandler(
      searchTodosProjectsQuery,
      searchTodosProjectsQueryHandler,
    );
    wrapper = mount(ProjectToken, {
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

  const itRendersToken = (project) => {
    const [tokenName, , tokenValue] = findGlFilteredSearchTokenSegments().wrappers;

    expect(tokenName.text()).toBe(mockToken.title);
    expect(tokenValue.text()).toBe(project.name);
  };

  beforeEach(() => {
    gon.api_version = 'v4';
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it("fetches the initially selected project's info if any, delaying the base token's rendering", async () => {
    axiosMock.onGet(mockProjectInfoEndpoint).reply(200, mockProject);
    createComponent({
      props: { value: { data: mockProject.id } },
      // Prevent the suggestions query from resolving to prevent false positives
      searchTodosProjectsQueryHandler: () => new Promise(),
    });

    expect(findBaseToken().exists()).toBe(false);

    await waitForPromises();

    expect(findBaseToken().exists()).toBe(true);
    itRendersToken(mockProject);
  });

  it("creates an alert if it fails to fetch the initially selected project's info", async () => {
    axiosMock.onGet(mockProjectInfoEndpoint).reply(404);
    createComponent({ props: { value: { data: mockProject.id } } });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'There was a problem fetching projects.',
      error: expect.any(Error),
    });
  });

  it('starts fetching suggestions on mount', async () => {
    createComponent();
    await nextTick();

    expect(searchTodosProjectsQuerySuccessHandler).toHaveBeenCalled();
    expect(findBaseToken().props('suggestionsLoading')).toBe(true);

    await waitForPromises();

    expect(findBaseToken().props('suggestionsLoading')).toBe(false);
  });

  it('sets the loading state while fetching suggestions', async () => {
    createComponent();

    await waitForPromises();

    expect(findBaseToken().props('suggestionsLoading')).toBe(false);

    triggerFetchSuggestions('project');
    await nextTick();

    expect(findBaseToken().props('suggestionsLoading')).toBe(true);
  });

  it("renders the projects' full paths in the suggestions list", () => {
    createComponent({
      stubs: {
        AsyncToken: stubComponent(AsyncToken, {
          data() {
            return {
              suggestions: [...todosProjectsResponse.data.projects.nodes],
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

    todosProjectsResponse.data.projects.nodes.forEach((project, i) => {
      expect(suggestionTexts[i]).toBe(project.fullPath);
    });
  });

  it("renders the selected project's token", async () => {
    const selectedProject = todosProjectsResponse.data.projects.nodes[0];
    createComponent({
      props: {
        value: { data: String(getIdFromGraphQLId(selectedProject.id)) },
      },
    });
    await waitForPromises();

    const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
    const [tokenName, , tokenValue] = tokenSegments.wrappers;

    expect(tokenName.text()).toBe(mockToken.title);
    expect(tokenValue.text()).toBe(selectedProject.name);
  });

  it('creates an alert if the query fails', async () => {
    createComponent({
      searchTodosProjectsQueryHandler: jest.fn().mockRejectedValue(),
    });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({ message: 'There was a problem fetching projects.' });
  });
});
