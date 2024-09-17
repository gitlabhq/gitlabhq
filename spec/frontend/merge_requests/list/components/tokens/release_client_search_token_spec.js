import {
  GlFilteredSearchSuggestion,
  GlFilteredSearchToken,
  GlFilteredSearchTokenSegment,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { createAlert } from '~/alert';
import ReleaseToken from '~/merge_requests/list/components/tokens/release_client_search_token.vue';
import {
  TOKEN_TITLE_RELEASE,
  TOKEN_TYPE_RELEASE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

const RELEASES_ENDPOINT = '/releases.json';

const mockReleaseToken = {
  type: TOKEN_TYPE_RELEASE,
  icon: 'rocket',
  title: TOKEN_TITLE_RELEASE,
  token: ReleaseToken,
  releasesEndpoint: RELEASES_ENDPOINT,
};

jest.mock('~/alert');

describe('ReleaseToken with client-side search', () => {
  const id = 'v1';
  let wrapper;
  let mockAxios;

  const createComponent = ({
    config = mockReleaseToken,
    value = { data: '' },
    active = false,
  } = {}) =>
    mount(ReleaseToken, {
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
    mockAxios.onGet(RELEASES_ENDPOINT).reply(HTTP_STATUS_OK, [
      { id: 1, tag: 'v1' },
      { id: 2, tag: 'v2' },
    ]);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  it('renders release value', async () => {
    wrapper = createComponent({ value: { data: id } });
    await nextTick();

    const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

    expect(tokenSegments).toHaveLength(3); // `Release` `=` `v1`
    expect(tokenSegments.at(2).text()).toBe(id.toString());
  });

  it('fetches all tags', async () => {
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
    expect(suggestions.at(0).text()).toBe('v1');
    expect(suggestions.at(1).text()).toBe('v2');
  });

  it('filters tags on client side', async () => {
    wrapper = createComponent();
    await axios.waitForAll();
    wrapper.setProps({ active: true });

    findTokenSegments().at(1).vm.$emit('next');
    await nextTick();
    findTokenSegments().at(2).vm.$emit('activate');
    await nextTick();

    wrapper.findComponent(GlFilteredSearchToken).vm.$emit('input', { data: 'v2' });
    await nextTick();

    const suggestions = findSuggestions();

    expect(suggestions).toHaveLength(1);
    expect(suggestions.at(0).text()).toBe('v2');
    expect(mockAxios.history.get).toHaveLength(1);
  });

  it('renders error message when request fails', async () => {
    mockAxios.onGet(RELEASES_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

    wrapper = createComponent();
    await axios.waitForAll();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'There was a problem fetching releases.',
    });
  });
});
