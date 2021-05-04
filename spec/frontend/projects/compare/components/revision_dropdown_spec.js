import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import RevisionDropdown from '~/projects/compare/components/revision_dropdown.vue';
import { revisionDropdownDefaultProps as defaultProps } from './mock_data';

jest.mock('~/flash');

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
    wrapper.destroy();
    axiosMock.restore();
  });

  const findGlDropdown = () => wrapper.find(GlDropdown);
  const findSearchBox = () => wrapper.find(GlSearchBoxByType);

  it('sets hidden input', () => {
    createComponent();
    expect(wrapper.find('input[type="hidden"]').attributes('value')).toBe(
      defaultProps.paramsBranch,
    );
  });

  it('update the branches on success', async () => {
    const Branches = ['branch-1', 'branch-2'];
    const Tags = ['tag-1', 'tag-2', 'tag-3'];

    axiosMock.onGet(defaultProps.refsProjectPath).replyOnce(200, {
      Branches,
      Tags,
    });

    createComponent();

    await axios.waitForAll();
    expect(wrapper.vm.branches).toEqual(Branches);
    expect(wrapper.vm.tags).toEqual(Tags);
  });

  it('shows flash message on error', async () => {
    axiosMock.onGet('some/invalid/path').replyOnce(404);

    createComponent();

    await wrapper.vm.fetchBranchesAndTags();
    expect(createFlash).toHaveBeenCalled();
  });

  it('makes a new request when refsProjectPath is changed', async () => {
    jest.spyOn(axios, 'get');

    const newRefsProjectPath = 'new-selected-project-path';

    createComponent();

    wrapper.setProps({
      ...defaultProps,
      refsProjectPath: newRefsProjectPath,
    });

    await axios.waitForAll();
    expect(axios.get).toHaveBeenLastCalledWith(newRefsProjectPath);
  });

  describe('search', () => {
    it('shows flash message on error', async () => {
      axiosMock.onGet('some/invalid/path').replyOnce(404);

      createComponent();

      await wrapper.vm.searchBranchesAndTags();
      expect(createFlash).toHaveBeenCalled();
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
      await axios.waitForAll();

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
    createComponent();
    wrapper.vm.branches = ['some-branch'];
    await wrapper.vm.$nextTick();

    findGlDropdown().findAll(GlDropdownItem).at(0).vm.$emit('click');

    expect(wrapper.emitted('selectRevision')[0][0]).toEqual({
      direction: 'to',
      revision: 'some-branch',
    });
  });
});
