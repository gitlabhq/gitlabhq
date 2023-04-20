import { GlEmptyState, GlLoadingIcon, GlTable } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import ImportErrorDetails from '~/pages/import/history/components/import_error_details.vue';
import ImportHistoryApp from '~/pages/import/history/components/import_history_app.vue';
import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';

describe('ImportHistoryApp', () => {
  const API_URL = '/api/v4/projects.json';

  const DEFAULT_HEADERS = {
    'x-page': 1,
    'x-per-page': 20,
    'x-next-page': 2,
    'x-total': 22,
    'x-total-pages': 2,
    'x-prev-page': null,
  };
  const DUMMY_RESPONSE = [
    {
      id: 1,
      path_with_namespace: 'root/imported',
      created_at: '2022-03-10T15:10:03.172Z',
      import_url: null,
      import_type: 'gitlab_project',
      import_status: 'finished',
    },
    {
      id: 2,
      name_with_namespace: 'Administrator / Dummy',
      path_with_namespace: 'root/dummy',
      created_at: '2022-03-09T11:23:04.974Z',
      import_url: 'https://dummy.github/url',
      import_type: 'github',
      import_status: 'failed',
    },
    {
      id: 3,
      name_with_namespace: 'Administrator / Dummy',
      path_with_namespace: 'root/dummy2',
      created_at: '2022-03-09T11:23:04.974Z',
      import_url: 'git://non-http.url',
      import_type: 'gi',
      import_status: 'finished',
    },
  ];
  let wrapper;
  let mock;

  function createComponent({ shallow = true } = {}) {
    const mountFn = shallow ? shallowMount : mount;
    wrapper = mountFn(ImportHistoryApp, {
      provide: { assets: { gitlabLogo: 'http://dummy.host' } },
      stubs: shallow ? { GlTable: { ...stubComponent(GlTable), props: ['items'] } } : {},
    });
  }

  beforeEach(() => {
    gon.api_version = 'v4';
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('general behavior', () => {
    it('renders loading state when loading', () => {
      createComponent();
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('renders empty state when no data is available', async () => {
      mock.onGet(API_URL).reply(HTTP_STATUS_OK, [], DEFAULT_HEADERS);
      createComponent();
      await axios.waitForAll();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('renders table with data when history is available', async () => {
      mock.onGet(API_URL).reply(HTTP_STATUS_OK, DUMMY_RESPONSE, DEFAULT_HEADERS);
      createComponent();
      await axios.waitForAll();

      const table = wrapper.findComponent(GlTable);
      expect(table.exists()).toBe(true);
      expect(table.props().items).toStrictEqual(DUMMY_RESPONSE);
    });

    it('changes page when requested by pagination bar', async () => {
      const NEW_PAGE = 4;

      mock.onGet(API_URL).reply(HTTP_STATUS_OK, DUMMY_RESPONSE, DEFAULT_HEADERS);
      createComponent();
      await axios.waitForAll();
      mock.resetHistory();

      const FAKE_NEXT_PAGE_REPLY = [
        {
          id: 4,
          path_with_namespace: 'root/some_other_project',
          created_at: '2022-03-10T15:10:03.172Z',
          import_url: null,
          import_type: 'gitlab_project',
          import_status: 'finished',
        },
      ];

      mock.onGet(API_URL).reply(HTTP_STATUS_OK, FAKE_NEXT_PAGE_REPLY, DEFAULT_HEADERS);

      wrapper.findComponent(PaginationBar).vm.$emit('set-page', NEW_PAGE);
      await axios.waitForAll();

      expect(mock.history.get.length).toBe(1);
      expect(mock.history.get[0].params).toStrictEqual(expect.objectContaining({ page: NEW_PAGE }));
      expect(wrapper.findComponent(GlTable).props().items).toStrictEqual(FAKE_NEXT_PAGE_REPLY);
    });
  });

  it('changes page size when requested by pagination bar', async () => {
    const NEW_PAGE_SIZE = 4;

    mock.onGet(API_URL).reply(HTTP_STATUS_OK, DUMMY_RESPONSE, DEFAULT_HEADERS);
    createComponent();
    await axios.waitForAll();
    mock.resetHistory();

    wrapper.findComponent(PaginationBar).vm.$emit('set-page-size', NEW_PAGE_SIZE);
    await axios.waitForAll();

    expect(mock.history.get.length).toBe(1);
    expect(mock.history.get[0].params).toStrictEqual(
      expect.objectContaining({ per_page: NEW_PAGE_SIZE }),
    );
  });

  it('resets page to 1 when page size is changed', async () => {
    const NEW_PAGE_SIZE = 4;

    mock.onGet(API_URL).reply(HTTP_STATUS_OK, DUMMY_RESPONSE, DEFAULT_HEADERS);
    createComponent();
    await axios.waitForAll();
    wrapper.findComponent(PaginationBar).vm.$emit('set-page', 2);
    await axios.waitForAll();
    mock.resetHistory();

    wrapper.findComponent(PaginationBar).vm.$emit('set-page-size', NEW_PAGE_SIZE);
    await axios.waitForAll();

    expect(mock.history.get.length).toBe(1);
    expect(mock.history.get[0].params).toStrictEqual(
      expect.objectContaining({ per_page: NEW_PAGE_SIZE, page: 1 }),
    );
  });

  describe('details button', () => {
    beforeEach(() => {
      mock.onGet(API_URL).reply(HTTP_STATUS_OK, DUMMY_RESPONSE, DEFAULT_HEADERS);
      createComponent({ shallow: false });
      return axios.waitForAll();
    });

    it('renders details button if relevant item has failed', () => {
      expect(
        extendedWrapper(wrapper.find('tbody').findAll('tr').at(1)).findByText('Details').exists(),
      ).toBe(true);
    });

    it('does not render details button if relevant item does not failed', () => {
      expect(
        extendedWrapper(wrapper.find('tbody').findAll('tr').at(0)).findByText('Details').exists(),
      ).toBe(false);
    });

    it('expands details when details button is clicked', async () => {
      const ORIGINAL_ROW_INDEX = 1;
      await extendedWrapper(wrapper.find('tbody').findAll('tr').at(ORIGINAL_ROW_INDEX))
        .findByText('Details')
        .trigger('click');

      const detailsRowContent = wrapper
        .find('tbody')
        .findAll('tr')
        .at(ORIGINAL_ROW_INDEX + 1)
        .findComponent(ImportErrorDetails);

      expect(detailsRowContent.exists()).toBe(true);
      expect(detailsRowContent.props().id).toBe(DUMMY_RESPONSE[1].id);
    });
  });
});
