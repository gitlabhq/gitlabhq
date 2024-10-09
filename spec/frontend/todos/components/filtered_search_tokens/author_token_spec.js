import { GlFilteredSearchTokenSegment, GlAvatar } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import AuthorToken from '~/todos/components/filtered_search_tokens/author_token.vue';
import AsyncToken from '~/todos/components/filtered_search_tokens/async_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { stubComponent } from 'helpers/stub_component';
import axios from '~/lib/utils/axios_utils';
import { todosAuthorsResponse } from '../../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

const mockToken = {
  type: 'author',
  icon: 'author',
  title: 'Author',
  unique: true,
  token: AuthorToken,
  operators: OPERATORS_IS,
  status: ['pending'],
};

describe('AuthorToken', () => {
  let wrapper;
  let axiosMock;

  function createComponent({ props = {}, data = {}, stubs = {} } = {}) {
    wrapper = mount(AuthorToken, {
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

  const triggerFetchSuggestions = (searchTerm = null) => {
    findBaseToken().vm.$emit('fetch-suggestions', searchTerm);
    return waitForPromises();
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    axiosMock.onGet('/-/autocomplete/users.json').reply(200, todosAuthorsResponse);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it('starts fetching suggestions on mount', async () => {
    createComponent();
    await nextTick();

    expect(findBaseToken().props('suggestionsLoading')).toBe(true);

    await waitForPromises();

    expect(findBaseToken().props('suggestionsLoading')).toBe(false);
  });

  it('sets the loading state while fetching suggestions', async () => {
    const searchQuery = 'Mr. Tanuki';
    createComponent();
    await waitForPromises();

    expect(findBaseToken().props('suggestionsLoading')).toBe(false);

    triggerFetchSuggestions(searchQuery);
    await nextTick();

    expect(findBaseToken().props('suggestionsLoading')).toBe(true);

    await waitForPromises();

    expect(axiosMock.history.get[axiosMock.history.get.length - 1].params).toEqual({
      active: true,
      search: searchQuery,
      todo_filter: true,
      todo_state_filter: ['pending'],
    });
  });

  it("renders the authors' avatars, names and usernames in the suggestions list", () => {
    createComponent({
      stubs: {
        AsyncToken: stubComponent(AsyncToken, {
          data() {
            return {
              suggestions: [...todosAuthorsResponse],
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
    const avatars = wrapper.findAllComponents(GlAvatar);

    todosAuthorsResponse.forEach((author, index) => {
      expect(avatars.at(index).props()).toEqual(
        expect.objectContaining({
          alt: author.name,
          entityName: author.username,
          src: author.avatar_url,
          shape: 'circle',
          size: 32,
        }),
      );
    });
    expect(wrapper.text()).toBe(
      todosAuthorsResponse.flatMap((author) => [author.name, `@${author.username}`]).join(' '),
    );
  });

  it("renders the selected author's token", async () => {
    const selectedAuthor = todosAuthorsResponse[0];
    createComponent({
      props: {
        value: { data: String(selectedAuthor.id) },
      },
    });
    await waitForPromises();

    const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
    const [tokenName, , tokenValue] = tokenSegments.wrappers;

    expect(tokenName.text()).toBe(mockToken.title);
    expect(tokenValue.text()).toBe(selectedAuthor.name);
  });

  it('creates an alert if the query fails', async () => {
    axiosMock.onGet('/-/autocomplete/users.json').reply(500);
    createComponent();
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({ message: 'There was a problem fetching authors.' });
  });
});
