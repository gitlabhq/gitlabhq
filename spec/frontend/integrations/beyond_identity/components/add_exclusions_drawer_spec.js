import { nextTick } from 'vue';
import { GlDrawer } from '@gitlab/ui';
import AddExclusionsDrawer from '~/integrations/beyond_identity/components/add_exclusions_drawer.vue';
import ListSelector from '~/vue_shared/components/list_selector/index.vue';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { groupExclusionsMock, projectExclusionsMock } from './mock_data';

jest.mock('~/lib/utils/dom_utils', () => ({
  getContentWrapperHeight: jest.fn(),
}));

describe('AddExclusionsDrawer component', () => {
  let wrapper;

  const findTitle = () => wrapper.findByTestId('title');
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findListSelectors = () => wrapper.findAllComponents(ListSelector);
  const findGroupsListSelector = () => findListSelectors().at(0);
  const findProjectsListSelector = () => findListSelectors().at(1);
  const findAddExclusionsButton = () => wrapper.findByTestId('add-button');

  const createComponent = (props) => {
    return shallowMountExtended(AddExclusionsDrawer, {
      propsData: { isOpen: true, ...props },
    });
  };

  describe('default behavior', () => {
    const mockHeaderHeight = '50px';

    beforeEach(() => {
      getContentWrapperHeight.mockReturnValue(mockHeaderHeight);
      wrapper = createComponent();
    });

    it('configures the drawer with header height and z-index', () => {
      expect(findDrawer().props()).toMatchObject({
        headerHeight: mockHeaderHeight,
        zIndex: DRAWER_Z_INDEX,
      });
    });
  });

  describe('when closed', () => {
    beforeEach(() => {
      wrapper = createComponent({ isOpen: false });
    });

    it('the drawer is not shown', () => {
      expect(findDrawer().props('open')).toBe(false);
    });
  });

  describe('when open', () => {
    beforeEach(() => {
      wrapper = createComponent({ isOpen: true });
    });

    it('opens the drawer', () => {
      expect(findDrawer().props('open')).toBe(true);
    });

    it('renders a title', () => {
      expect(findTitle().text()).toEqual('Add exclusions');
    });

    it('renders a list selector for groups', () => {
      expect(findGroupsListSelector().props()).toMatchObject({
        type: 'groups',
        autofocus: true,
        disableNamespaceDropdown: true,
      });
    });

    it('renders a list selector for projects', () => {
      expect(findProjectsListSelector().props('type')).toBe('projects');
    });

    it('renders a button for adding exclusions', () => {
      expect(findAddExclusionsButton().exists()).toBe(true);
    });
  });

  it.each`
    type         | findSelector                | mockData
    ${'group'}   | ${findGroupsListSelector}   | ${groupExclusionsMock}
    ${'project'} | ${findProjectsListSelector} | ${projectExclusionsMock}
  `('handles selected $type exclusions', async ({ findSelector, mockData }) => {
    wrapper = createComponent({ showDrawer: true });

    findSelector().vm.$emit('select', mockData[0]);
    findSelector().vm.$emit('select', mockData[1]);
    await nextTick();

    expect(findSelector().props('selectedItems')).toEqual(mockData);

    findAddExclusionsButton().vm.$emit('click');
    await nextTick();

    expect(wrapper.emitted('add')).toEqual([[mockData]]);
    expect(findSelector().props('selectedItems').length).toBe(0);
  });
});
