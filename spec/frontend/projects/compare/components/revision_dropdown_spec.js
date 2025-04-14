import { nextTick } from 'vue';
import { GlCollapsibleListbox } from '@gitlab/ui';
import AxiosMockAdapter from 'axios-mock-adapter';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import RevisionDropdown from '~/projects/compare/components/revision_dropdown.vue';
import { logError } from '~/lib/logger';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  expectedBranchesItems,
  expectedItems,
  expectedTagsItems,
  revisionDropdownDefaultProps as defaultProps,
} from './mock_data';

jest.mock('~/alert');
jest.mock('~/lib/logger');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('RevisionDropdown component', () => {
  let wrapper;
  let axiosMock;

  const Branches = ['branch-1', 'branch-2'];
  const Tags = ['tag-1', 'tag-2', 'tag-3'];

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(RevisionDropdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  const findGlListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findGlListboxSearchInput = () => wrapper.findByTestId('listbox-search-input').find('input');

  beforeEach(() => {
    axiosMock.onGet(defaultProps.refsProjectPath).replyOnce(HTTP_STATUS_OK, {
      Branches,
      Tags,
    });

    createComponent();
  });

  it('sets hidden input', () => {
    expect(wrapper.find('input[type="hidden"]').attributes('value')).toBe(
      defaultProps.paramsBranch,
    );
  });

  describe('updates the branches and tags on success', () => {
    it.each`
      description                            | responseData          | expectedResult
      ${'includes both if both exists'}      | ${{ Branches, Tags }} | ${expectedItems}
      ${'does not include tags if none'}     | ${{ Branches }}       | ${expectedBranchesItems}
      ${'does not include branches if none'} | ${{ Tags }}           | ${expectedTagsItems}
    `('$description', async ({ responseData, expectedResult }) => {
      axiosMock.onGet(defaultProps.refsProjectPath).replyOnce(HTTP_STATUS_OK, responseData);

      createComponent();

      expect(findGlListbox().props('items')).toHaveLength(0);

      await waitForPromises();

      expect(findGlListbox().props('items')).toStrictEqual(expectedResult);
    });
  });

  it('shows an alert on error', async () => {
    const mockError = new Error('Request failed with status code 404');
    mockError.response = { status: HTTP_STATUS_NOT_FOUND };
    axiosMock.onGet(defaultProps.refsProjectPath).replyOnce(HTTP_STATUS_NOT_FOUND);

    createComponent();
    await waitForPromises();

    expect(createAlert).toHaveBeenCalled();
    expect(logError).toHaveBeenCalledWith(
      `There was an error while loading the branch/tag list. Please try again.`,
      mockError,
    );
    expect(Sentry.captureException).toHaveBeenCalledWith(mockError);
  });

  it('makes a new request when refsProjectPath is changed', async () => {
    jest.spyOn(axios, 'get');

    const newRefsProjectPath = 'new-selected-project-path';

    createComponent();

    wrapper.setProps({
      ...defaultProps,
      refsProjectPath: newRefsProjectPath,
    });

    await waitForPromises();
    expect(axios.get).toHaveBeenLastCalledWith(newRefsProjectPath);
  });

  describe('search', () => {
    it('makes request with search param', async () => {
      jest.spyOn(axios, 'get').mockResolvedValue({
        data: {
          Branches: [],
          Tags: [],
        },
      });

      const mockSearchTerm = 'foobar';
      createComponent();

      findGlListbox().vm.$emit('search', mockSearchTerm);
      await waitForPromises();

      expect(axios.get).toHaveBeenCalledWith(
        defaultProps.refsProjectPath,
        expect.objectContaining({
          params: {
            search: mockSearchTerm,
          },
        }),
      );
    });

    it('should handle enter key', async () => {
      const mockCommitHash = '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9';
      wrapper = mountExtended(RevisionDropdown, {
        propsData: {
          ...defaultProps,
        },
      });

      const mockClose = jest.spyOn(
        wrapper.vm.$refs.collapsibleDropdown.$refs.baseDropdown,
        'close',
      );

      findGlListbox().vm.$emit('shown');
      findGlListboxSearchInput().element.value = mockCommitHash;
      await findGlListboxSearchInput().trigger('keydown', { code: 'Enter' });
      await nextTick();

      expect(mockClose).toHaveBeenCalled();
      expect(findGlListbox().props('toggleText')).toBe(mockCommitHash);
    });
  });

  describe('GlCollapsibleListbox component', () => {
    it('renders with correct props', () => {
      createComponent({
        paramsBranch: null,
      });
      expect(findGlListbox().props()).toMatchObject({
        block: true,
        headerText: 'Select Git revision',
        items: [],
        searchPlaceholder: 'Filter by Git revision',
        searchable: true,
        searching: false,
        toggleClass: 'form-control compare-dropdown-toggle gl-min-w-0',
        toggleText: 'Select branch/tag',
      });
    });

    it('display params branch text', () => {
      expect(findGlListbox().props('toggleText')).toBe(defaultProps.paramsBranch);
    });
  });

  it('emits `select` event when another revision is selected', () => {
    findGlListbox().vm.$emit('select', 'some-branch');

    expect(wrapper.emitted('selectRevision')[0][0]).toEqual({
      direction: 'to',
      revision: 'some-branch',
    });
  });
});
