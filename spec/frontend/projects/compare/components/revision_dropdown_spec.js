import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import RevisionDropdown from '~/projects/compare/components/revision_dropdown.vue';
import { revisionDropdownDefaultProps as defaultProps } from './mock_data';

jest.mock('~/alert');

describe('RevisionDropdown component', () => {
  let wrapper;
  let axiosMock;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(RevisionDropdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlDropdown,
        GlSearchBoxByType,
      },
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  const findGlDropdown = () => wrapper.findComponent(GlDropdown);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findBranchesDropdownItem = () =>
    wrapper.findAllComponents('[data-testid="branches-dropdown-item"]');
  const findTagsDropdownItem = () =>
    wrapper.findAllComponents('[data-testid="tags-dropdown-item"]');

  it('sets hidden input', () => {
    createComponent();
    expect(wrapper.find('input[type="hidden"]').attributes('value')).toBe(
      defaultProps.paramsBranch,
    );
  });

  it('update the branches on success', async () => {
    const Branches = ['branch-1', 'branch-2'];
    const Tags = ['tag-1', 'tag-2', 'tag-3'];

    axiosMock.onGet(defaultProps.refsProjectPath).replyOnce(HTTP_STATUS_OK, {
      Branches,
      Tags,
    });

    createComponent();

    expect(findBranchesDropdownItem()).toHaveLength(0);
    expect(findTagsDropdownItem()).toHaveLength(0);

    await waitForPromises();

    expect(findBranchesDropdownItem()).toHaveLength(Branches.length);
    expect(findTagsDropdownItem()).toHaveLength(Tags.length);

    Branches.forEach((branch, index) => {
      expect(findBranchesDropdownItem().at(index).text()).toBe(branch);
    });

    Tags.forEach((tag, index) => {
      expect(findTagsDropdownItem().at(index).text()).toBe(tag);
    });
  });

  it('shows an alert on error', async () => {
    axiosMock.onGet('some/invalid/path').replyOnce(HTTP_STATUS_NOT_FOUND);

    createComponent();
    await waitForPromises();

    expect(createAlert).toHaveBeenCalled();
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
    it('shows alert on error', async () => {
      axiosMock.onGet('some/invalid/path').replyOnce(HTTP_STATUS_NOT_FOUND);

      createComponent();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalled();
    });

    it('makes request with search param', async () => {
      jest.spyOn(axios, 'get').mockResolvedValue({
        data: {
          Branches: [],
          Tags: [],
        },
      });

      const mockSearchTerm = 'foobar';
      createComponent();
      findSearchBox().vm.$emit('input', mockSearchTerm);
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
  });

  describe('GlDropdown component', () => {
    it('renders props', () => {
      createComponent();
      expect(wrapper.props()).toEqual(expect.objectContaining(defaultProps));
    });

    it('display default text', () => {
      createComponent({
        paramsBranch: null,
      });
      expect(findGlDropdown().props('text')).toBe('Select branch/tag');
    });

    it('display params branch text', () => {
      createComponent();
      expect(findGlDropdown().props('text')).toBe(defaultProps.paramsBranch);
    });
  });

  it('emits `selectRevision` event when another revision is selected', async () => {
    jest.spyOn(axios, 'get').mockResolvedValue({
      data: {
        Branches: ['some-branch'],
        Tags: [],
      },
    });

    createComponent();
    await nextTick();

    findGlDropdown().findAllComponents(GlDropdownItem).at(0).vm.$emit('click');

    expect(wrapper.emitted('selectRevision')[0][0]).toEqual({
      direction: 'to',
      revision: 'some-branch',
    });
  });
});
