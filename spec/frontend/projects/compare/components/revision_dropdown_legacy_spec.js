import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import RevisionDropdown from '~/projects/compare/components/revision_dropdown_legacy.vue';

const defaultProps = {
  refsProjectPath: 'some/refs/path',
  revisionText: 'Target',
  paramsName: 'from',
  paramsBranch: 'main',
};

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
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    axiosMock.restore();
  });

  const findGlDropdown = () => wrapper.findComponent(GlDropdown);

  it('sets hidden input', () => {
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

  it('sets branches and tags to be an empty array when no tags or branches are given', async () => {
    axiosMock.onGet(defaultProps.refsProjectPath).replyOnce(200, {
      Branches: undefined,
      Tags: undefined,
    });

    await axios.waitForAll();

    expect(wrapper.vm.branches).toEqual([]);
    expect(wrapper.vm.tags).toEqual([]);
  });

  it('shows flash message on error', async () => {
    axiosMock.onGet('some/invalid/path').replyOnce(HTTP_STATUS_NOT_FOUND);

    await wrapper.vm.fetchBranchesAndTags();
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

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ branches: ['some-branch'] });

      await nextTick();

      findFirstGlDropdownItem().vm.$emit('click');

      expect(wrapper.emitted()).toEqual({
        selectRevision: [[{ direction: 'from', revision: 'some-branch' }]],
      });
    });
  });
});
