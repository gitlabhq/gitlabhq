import {
  GlFilteredSearchSuggestion,
  GlFilteredSearchToken,
  GlFilteredSearchTokenSegment,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { createAlert } from '~/alert';
import EnvironmentToken from '~/merge_requests/list/components/tokens/environment_token.vue';
import {
  TOKEN_TITLE_ENVIRONMENT,
  TOKEN_TYPE_ENVIRONMENT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

const ENVIRONMENTS_ENDPOINT = '/environments.json';

const mockEnvironmentToken = {
  type: TOKEN_TYPE_ENVIRONMENT,
  icon: 'environment',
  title: TOKEN_TITLE_ENVIRONMENT,
  token: EnvironmentToken,
  environmentsEndpoint: ENVIRONMENTS_ENDPOINT,
};

jest.mock('~/alert');

describe('EnvironmentToken', () => {
  const id = 'prod';
  let wrapper;
  let mockAxios;

  const createComponent = ({
    config = mockEnvironmentToken,
    value = { data: '' },
    active = false,
  } = {}) =>
    mount(EnvironmentToken, {
      propsData: {
        active,
        config,
        value,
        cursorPosition: 'start',
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: function fakeAlignSuggestions() {},
        suggestionsListClass: () => 'custom-class',
        termsAsTokens: () => false,
      },
      stubs: {
        Portal: true,
      },
    });

  const findSuggestions = () => wrapper.findAllComponents(GlFilteredSearchSuggestion);
  const findTokenSegments = () => wrapper.findAllComponents(GlFilteredSearchTokenSegment);

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(ENVIRONMENTS_ENDPOINT).reply(HTTP_STATUS_OK, ['prod', 'qa']);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  it('renders environment name', async () => {
    wrapper = createComponent({ value: { data: id } });
    await nextTick();

    const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

    expect(tokenSegments).toHaveLength(3);
    expect(tokenSegments.at(2).text()).toBe(id.toString());
  });

  it('fetches all environments', async () => {
    wrapper = createComponent();
    await axios.waitForAll();
    wrapper.setProps({ active: true });

    findTokenSegments().at(1).vm.$emit('next');
    await nextTick();
    findTokenSegments().at(2).vm.$emit('activate');
    await nextTick();

    const suggestions = findSuggestions();

    await nextTick();

    expect(suggestions).toHaveLength(2);
    expect(suggestions.at(0).text()).toBe('prod');
    expect(suggestions.at(1).text()).toBe('qa');
  });

  it('filters environments on client side', async () => {
    wrapper = createComponent();
    await axios.waitForAll();
    wrapper.setProps({ active: true });

    findTokenSegments().at(1).vm.$emit('next');
    await nextTick();
    findTokenSegments().at(2).vm.$emit('activate');
    await nextTick();

    wrapper.findComponent(GlFilteredSearchToken).vm.$emit('input', { data: 'prod' });
    await nextTick();

    const suggestions = findSuggestions();

    expect(suggestions).toHaveLength(1);
    expect(suggestions.at(0).text()).toBe('prod');
    expect(mockAxios.history.get).toHaveLength(1);
  });

  it('renders error message when request fails', async () => {
    mockAxios.onGet(ENVIRONMENTS_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

    wrapper = createComponent();
    await axios.waitForAll();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'There was a problem fetching environments.',
    });
  });
});
