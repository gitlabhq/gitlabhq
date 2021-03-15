import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import IssuableList from '~/issuable_list/components/issuable_list_root.vue';
import IssuesListApp from '~/issues_list/components/issues_list_app.vue';
import axios from '~/lib/utils/axios_utils';

describe('IssuesListApp component', () => {
  let axiosMock;
  let wrapper;

  const fullPath = 'path/to/project';
  const endpoint = 'api/endpoint';
  const state = 'opened';
  const xPage = 1;
  const xTotal = 25;
  const fetchIssuesResponse = {
    data: [],
    headers: {
      'x-page': xPage,
      'x-total': xTotal,
    },
  };

  const findIssuableList = () => wrapper.findComponent(IssuableList);

  const mountComponent = () =>
    shallowMount(IssuesListApp, {
      provide: {
        endpoint,
        fullPath,
      },
    });

  beforeEach(async () => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(endpoint).reply(200, fetchIssuesResponse.data, fetchIssuesResponse.headers);
    wrapper = mountComponent();
    await waitForPromises();
  });

  afterEach(() => {
    axiosMock.reset();
    wrapper.destroy();
  });

  it('renders IssuableList', () => {
    expect(findIssuableList().props()).toMatchObject({
      namespace: fullPath,
      recentSearchesStorageKey: 'issues',
      searchInputPlaceholder: 'Search or filter results…',
      showPaginationControls: true,
      issuables: [],
      totalItems: xTotal,
      currentPage: xPage,
      previousPage: xPage - 1,
      nextPage: xPage + 1,
      urlParams: { page: xPage, state },
    });
  });

  describe('when "page-change" event is emitted', () => {
    const data = [{ id: 10, title: 'title', state }];
    const page = 2;
    const totalItems = 21;

    beforeEach(async () => {
      axiosMock.onGet(endpoint).reply(200, data, {
        'x-page': page,
        'x-total': totalItems,
      });

      findIssuableList().vm.$emit('page-change', page);

      await waitForPromises();
    });

    it('fetches issues with expected params', async () => {
      expect(axiosMock.history.get[1].params).toEqual({
        page,
        per_page: 20,
        state,
        with_labels_details: true,
      });
    });

    it('updates IssuableList with response data', () => {
      expect(findIssuableList().props()).toMatchObject({
        issuables: data,
        totalItems,
        currentPage: page,
        previousPage: page - 1,
        nextPage: page + 1,
        urlParams: { page, state },
      });
    });
  });
});
