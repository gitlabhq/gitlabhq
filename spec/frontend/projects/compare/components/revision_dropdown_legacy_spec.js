import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import RevisionDropdown from '~/projects/compare/components/revision_dropdown_legacy.vue';

const defaultProps = {
  refsProjectPath: 'some/refs/path',
  revisionText: 'Target',
  paramsName: 'from',
  paramsBranch: 'main',
};

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
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    axiosMock.restore();
  });

  const findGlDropdown = () => wrapper.findComponent(GlDropdown);
  const findBranchesDropdownItem = () =>
    wrapper.findAllComponents('[data-testid="branches-dropdown-item"]');
  const findTagsDropdownItem = () =>
    wrapper.findAllComponents('[data-testid="tags-dropdown-item"]');

  it('sets hidden input', () => {
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

    Branches.forEach((branch, index) => {
      expect(findBranchesDropdownItem().at(index).text()).toBe(branch);
    });

    Tags.forEach((tag, index) => {
      expect(findTagsDropdownItem().at(index).text()).toBe(tag);
    });

    expect(findBranchesDropdownItem()).toHaveLength(Branches.length);
    expect(findTagsDropdownItem()).toHaveLength(Tags.length);
  });

  it('sets branches and tags to be an empty array when no tags or branches are given', async () => {
    axiosMock.onGet(defaultProps.refsProjectPath).replyOnce(HTTP_STATUS_OK, {
      Branches: undefined,
      Tags: undefined,
    });

    await waitForPromises();

    expect(findBranchesDropdownItem()).toHaveLength(0);
    expect(findTagsDropdownItem()).toHaveLength(0);
  });

  it('shows an alert on error', async () => {
    axiosMock.onGet('some/invalid/path').replyOnce(HTTP_STATUS_NOT_FOUND);

    await waitForPromises();

    expect(createAlert).toHaveBeenCalled();
  });

  describe('GlDropdown component', () => {
    it('renders props', () => {
      expect(wrapper.props()).toEqual(expect.objectContaining(defaultProps));
    });

    it('display default text', () => {
      createComponent({
        paramsBranch: null,
      });
      expect(findGlDropdown().props('text')).toBe('Select branch/tag');
    });

    it('display params branch text', () => {
      expect(findGlDropdown().props('text')).toBe(defaultProps.paramsBranch);
    });

    it('emits a "selectRevision" event when a revision is selected', async () => {
      const findGlDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
      const findFirstGlDropdownItem = () => findGlDropdownItems().at(0);
      const branchName = 'some-branch';

      axiosMock.onGet(defaultProps.refsProjectPath).replyOnce(HTTP_STATUS_OK, {
        Branches: [branchName],
      });

      createComponent();
      await waitForPromises();

      findFirstGlDropdownItem().vm.$emit('click');

      expect(wrapper.emitted()).toEqual({
        selectRevision: [[{ direction: 'from', revision: branchName }]],
      });
    });
  });
});
