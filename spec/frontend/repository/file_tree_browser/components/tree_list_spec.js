import Vue from 'vue';
import { GlFormInput, GlIcon } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { RecycleScroller } from 'vendor/vue-virtual-scroller';
import TreeList from '~/repository/file_tree_browser/components/tree_list.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import { stubComponent } from 'helpers/stub_component';
import createMockApollo from 'helpers/mock_apollo_helper';
import paginatedTreeQuery from 'shared_queries/repository/paginated_tree.query.graphql';
import { mockResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/repository/utils/ref_type', () => ({ getRefType: jest.fn(() => 'MOCK_REF_TYPE') }));
jest.mock('~/lib/utils/url_utility', () => ({ joinPaths: jest.fn((...args) => args.join('/')) }));

const getQueryHandlerSuccess = jest.fn().mockResolvedValue(mockResponse);

describe('Tree List', () => {
  let wrapper;
  let apolloProvider;

  const createComponent = async () => {
    apolloProvider = createMockApollo([[paginatedTreeQuery, getQueryHandlerSuccess]]);

    const recycleScrollerStub = stubComponent(
      {
        name: 'RecycleScroller',
        props: {
          items: { type: Array, required: true },
          itemSize: { type: Number, required: true },
          buffer: { type: Number, required: true },
          keyField: { type: String, required: true },
        },
      },
      {
        template: `<div><slot v-for="(item, index) in items" :item="item" :index="index"></slot></div>`,
      },
    );

    wrapper = shallowMountExtended(TreeList, {
      apolloProvider,
      propsData: { projectPath: 'group/project', currentRef: 'main', refType: 'branch' },
      mocks: { $route: { params: {}, $apollo: { query: jest.fn() } } },
      stubs: { RecycleScroller: recycleScrollerStub },
    });

    await waitForPromises();
  };

  beforeEach(() => createComponent());

  const findHeader = () => wrapper.find('h3');
  const findRecycleScroller = () => wrapper.findComponent(RecycleScroller);
  const findFileRows = () => wrapper.findAllComponents(FileRow);
  const findFilterInput = () => wrapper.findComponent(GlFormInput);
  const findFilterIcon = () => wrapper.findComponent(GlIcon);
  const findNoFilesMessage = () => wrapper.findByText('No files found');

  it('calls apollo query with correct parameters', () => {
    expect(getQueryHandlerSuccess).toHaveBeenCalledWith({
      projectPath: 'group/project',
      ref: 'main',
      refType: 'MOCK_REF_TYPE',
      path: '/',
      nextPageCursor: '',
      pageSize: 100,
    });
  });

  it('renders a title', () => {
    expect(findHeader().text()).toBe('Files');
  });

  it('renders recycle-scroller with correct props', () => {
    const scroller = findRecycleScroller();
    expect(scroller.props('items')).toEqual([
      {
        id: '/dir_1/dir_2-gid://123-0',
        isCurrentPath: false,
        level: 0,
        loading: false,
        name: 'dir_2',
        opened: false,
        path: '/dir_1/dir_2',
        routerPath: '/-/tree/main//dir_1/dir_2',
        type: 'tree',
      },
      {
        fileHash: 'abc123',
        id: '/dir_1/file.txt-gid://456-0',
        isCurrentPath: false,
        level: 0,
        mode: '100644',
        name: 'file.txt',
        path: '/dir_1/file.txt',
        routerPath: '/-/blob/main//dir_1/file.txt',
      },
    ]);

    expect(scroller.props()).toMatchObject({ itemSize: 32, buffer: 100, keyField: 'id' });
  });

  it('renders file rows with correct props', () => {
    const fileRows = findFileRows();

    expect(fileRows.at(0).props()).toMatchObject({
      file: {
        id: '/dir_1/dir_2-gid://123-0',
        isCurrentPath: false,
        level: 0,
        name: 'dir_2',
        path: '/dir_1/dir_2',
        routerPath: '/-/tree/main//dir_1/dir_2',
        type: 'tree',
      },
      fileUrl: '/-/tree/main//dir_1/dir_2',
      level: 0,
    });

    // File row
    expect(fileRows.at(1).props()).toMatchObject({
      file: {
        fileHash: 'abc123',
        id: '/dir_1/file.txt-gid://456-0',
        isCurrentPath: false,
        level: 0,
        mode: '100644',
        name: 'file.txt',
        path: '/dir_1/file.txt',
        routerPath: '/-/blob/main//dir_1/file.txt',
      },
      fileUrl: '/-/blob/main//dir_1/file.txt',
      level: 0,
    });
  });

  it('calls navigateTo with correct path when clickTree is emitted from FileRow', () => {
    const navigateTo = jest.spyOn(wrapper.vm, 'navigateTo').mockImplementation(() => {});
    const path = '/dir_1/dir_2';
    findFileRows().at(0).vm.$emit('clickTree', path);
    expect(navigateTo).toHaveBeenCalledWith(path);
  });

  describe('filtering', () => {
    it('renders filter input with icon', () => {
      expect(findFilterInput().exists()).toBe(true);
      expect(findFilterIcon().exists()).toBe(true);
      expect(findFilterIcon().props('name')).toBe('filter');
      expect(findFilterIcon().props('variant')).toBe('subtle');
      expect(findFilterInput().attributes('type')).toBe('search');
    });

    const filterTestCases = [
      { filter: 'file.txt', expectedNames: ['file.txt'] },
      { filter: '*.txt', expectedNames: ['file.txt'] },
      { filter: 'dir_2', expectedNames: ['dir_2'] },
      { filter: '*.nonexistent', expectedNames: [] },
    ];

    it.each(filterTestCases)('filters correctly with "$filter"', ({ filter, expectedNames }) => {
      findFilterInput().vm.$emit('input', filter);
      const fileNames = findFileRows().wrappers.map((row) => row.props('file').name);

      expect(fileNames).toEqual(expect.arrayContaining(expectedNames));
    });
  });

  describe('empty state', () => {
    it('shows no files message when filtered list is empty', async () => {
      findFilterInput().vm.$emit('input', '*.nonexistent');
      await waitForPromises();
      expect(findNoFilesMessage().exists()).toBe(true);
    });
  });
});
