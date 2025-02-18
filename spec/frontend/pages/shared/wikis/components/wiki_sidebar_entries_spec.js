import { GlSkeletonLoader, GlSearchBoxByType } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import WikiSidebarEntries from '~/pages/shared/wikis/components/wiki_sidebar_entries.vue';
import WikiSidebarEntry from '~/pages/shared/wikis/components/wiki_sidebar_entry.vue';

const MOCK_SIDEBAR_PAGES_API = 'sidebar/pages/api';
const MOCK_VIEW_ALL_PAGES_PATH = 'view/all/pages';

const MOCK_ENTRIES = [
  { title: '_sidebar', slug: '_sidebar', path: 'path/to/_sidebar' },
  { title: 'Page 1', slug: 'page-1', path: 'path/to/page-1' },
  { title: 'Page 2', slug: 'page-2', path: 'path/to/page-2' },
  { title: 'Page 2/3', slug: 'page-2/3', path: 'path/to/page-2/3' },
  { title: 'Page 3', slug: 'page-3', path: 'path/to/page-3' },
  { title: 'Page 4', slug: 'page-4', path: 'path/to/page-4' },
  { title: 'Page 5', slug: 'page-5', path: 'path/to/page-5' },
  { title: 'Page 6', slug: 'page-6', path: 'path/to/page-6' },
  { title: 'Page 7', slug: 'page-7', path: 'path/to/page-7' },
  { title: 'Page 8', slug: 'page-8', path: 'path/to/page-8' },
  { title: 'Page 9', slug: 'page-9', path: 'path/to/page-9' },
  { title: 'Page 10', slug: 'page-10', path: 'path/to/page-10' },
  { title: 'Page 11', slug: 'page-11', path: 'path/to/page-11' },
  { title: 'Page 12', slug: 'page-12', path: 'path/to/page-12' },
  { title: 'Page 13', slug: 'page-13', path: 'path/to/page-13' },
  { title: 'Page 14', slug: 'page-14', path: 'path/to/page-14' },
  { title: 'Page 15', slug: 'page-15', path: 'path/to/page-15' },
  { title: 'Page 16', slug: 'page-16', path: 'path/to/page-16' },
  { title: 'Page 17', slug: 'page-17', path: 'path/to/page-17' },
];

describe('pages/shared/wikis/components/wiki_sidebar_entry', () => {
  let wrapper;
  let mock;

  const findViewAllPagesButton = () => wrapper.findByTestId('view-all-pages-button');
  const findAllEntries = () => wrapper.findAllComponents(WikiSidebarEntry);
  const findAndMapEntriesToPages = () =>
    findAllEntries().wrappers.map((entry) => ({ ...entry.props('page') }));
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  function buildWrapper(props = {}, provide = {}) {
    wrapper = shallowMountExtended(WikiSidebarEntries, {
      propsData: props,
      provide: {
        hasCustomSidebar: false,
        sidebarPagesApi: MOCK_SIDEBAR_PAGES_API,
        viewAllPagesPath: MOCK_VIEW_ALL_PAGES_PATH,
        canCreate: false,
        ...provide,
      },
      stubs: {
        GlSearchBoxByType,
      },
    });
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('loading state', () => {
    beforeEach(() => {
      mock.onGet(MOCK_SIDEBAR_PAGES_API).reply(HTTP_STATUS_OK, MOCK_ENTRIES);
      buildWrapper();
    });

    it('shows skeleton loader while loading', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });

    it('hides the skeleton loader after loading is finished', async () => {
      await waitForPromises();

      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(false);
    });
  });

  describe('when the page count is 0', () => {
    beforeEach(() => {
      mock.onGet(MOCK_SIDEBAR_PAGES_API).reply(HTTP_STATUS_OK, []);
      buildWrapper();

      return waitForPromises();
    });

    it('does not list any entries', () => {
      expect(wrapper.findAllComponents(WikiSidebarEntry)).toHaveLength(0);
    });

    it('displays text "There are no pages in this wiki yet"', () => {
      expect(wrapper.text()).toContain('There are no pages in this wiki yet.');
    });

    it('does not display + X more text', () => {
      expect(wrapper.text()).not.toMatch(/\+ \d+ more/);
    });

    it('does not have a "View all pages" button', () => {
      expect(findViewAllPagesButton().exists()).toBe(false);
    });
  });

  describe('displaying a list of all pages', () => {
    beforeEach(() => {
      mock.onGet(MOCK_SIDEBAR_PAGES_API).reply(HTTP_STATUS_OK, MOCK_ENTRIES);
      buildWrapper();

      return waitForPromises();
    });

    it('lists all the root level entries except _sidebar', () => {
      expect(findAndMapEntriesToPages()).toEqual([
        { slug: 'page-1', path: 'path/to/page-1', title: 'Page 1', children: [] },
        {
          slug: 'page-2',
          path: 'path/to/page-2',
          title: 'Page 2',
          children: [
            { slug: 'page-2/3', path: 'path/to/page-2/3', title: 'Page 2/3', children: [] },
          ],
        },
        { slug: 'page-3', path: 'path/to/page-3', title: 'Page 3', children: [] },
        { slug: 'page-4', path: 'path/to/page-4', title: 'Page 4', children: [] },
        { slug: 'page-5', path: 'path/to/page-5', title: 'Page 5', children: [] },
        { slug: 'page-6', path: 'path/to/page-6', title: 'Page 6', children: [] },
        { slug: 'page-7', path: 'path/to/page-7', title: 'Page 7', children: [] },
        { slug: 'page-8', path: 'path/to/page-8', title: 'Page 8', children: [] },
        { slug: 'page-9', path: 'path/to/page-9', title: 'Page 9', children: [] },
        { slug: 'page-10', path: 'path/to/page-10', title: 'Page 10', children: [] },
        { slug: 'page-11', path: 'path/to/page-11', title: 'Page 11', children: [] },
        { slug: 'page-12', path: 'path/to/page-12', title: 'Page 12', children: [] },
        { slug: 'page-13', path: 'path/to/page-13', title: 'Page 13', children: [] },
        { slug: 'page-14', path: 'path/to/page-14', title: 'Page 14', children: [] },
        { slug: 'page-15', path: 'path/to/page-15', title: 'Page 15', children: [] },
        { slug: 'page-16', path: 'path/to/page-16', title: 'Page 16', children: [] },
        { slug: 'page-17', path: 'path/to/page-17', title: 'Page 17', children: [] },
      ]);
    });

    it('does not display + X more text', () => {
      expect(wrapper.text()).not.toMatch(/\+ \d+ more/);
    });

    it('has a "View all pages" button', () => {
      expect(findViewAllPagesButton().exists()).toBe(true);
      expect(findViewAllPagesButton().attributes('href')).toBe(MOCK_VIEW_ALL_PAGES_PATH);
    });
  });

  describe('when searching for pages', () => {
    beforeEach(async () => {
      mock.onGet(MOCK_SIDEBAR_PAGES_API).reply(HTTP_STATUS_OK, MOCK_ENTRIES);
      buildWrapper();

      await waitForPromises();

      findSearchBox().vm.$emit('input', 'Page 1');
    });

    it('lists all the filtered search results', () => {
      expect(findAndMapEntriesToPages()).toEqual([
        { slug: 'page-1', path: 'path/to/page-1', title: 'Page 1', children: [] },
        { slug: 'page-10', path: 'path/to/page-10', title: 'Page 10', children: [] },
        { slug: 'page-11', path: 'path/to/page-11', title: 'Page 11', children: [] },
        { slug: 'page-12', path: 'path/to/page-12', title: 'Page 12', children: [] },
        { slug: 'page-13', path: 'path/to/page-13', title: 'Page 13', children: [] },
        { slug: 'page-14', path: 'path/to/page-14', title: 'Page 14', children: [] },
        { slug: 'page-15', path: 'path/to/page-15', title: 'Page 15', children: [] },
        { slug: 'page-16', path: 'path/to/page-16', title: 'Page 16', children: [] },
        { slug: 'page-17', path: 'path/to/page-17', title: 'Page 17', children: [] },
      ]);
    });

    it('has a "View all pages" button', () => {
      expect(findViewAllPagesButton().exists()).toBe(true);
      expect(findViewAllPagesButton().attributes('href')).toBe(MOCK_VIEW_ALL_PAGES_PATH);
    });
  });
});
