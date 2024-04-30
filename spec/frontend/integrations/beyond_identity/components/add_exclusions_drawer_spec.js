import { GlDrawer } from '@gitlab/ui';
import AddExclusionsDrawer from '~/integrations/beyond_identity/components/add_exclusions_drawer.vue';
import ListSelector from '~/vue_shared/components/list_selector/index.vue';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { exclusionsMock } from './mock_data';

jest.mock('~/lib/utils/dom_utils', () => ({
  getContentWrapperHeight: jest.fn(),
}));

describe('AddExclusionsDrawer component', () => {
  let wrapper;

  const findTitle = () => wrapper.findByTestId('title');
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findListSelector = () => wrapper.findComponent(ListSelector);
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

    it('renders a project list selector', () => {
      expect(findListSelector().props('type')).toBe('projects');
    });

    it('renders a button for adding exclusions', () => {
      expect(findAddExclusionsButton().exists()).toBe(true);
    });
  });

  describe('when exclusions are selected', () => {
    beforeEach(() => {
      wrapper = createComponent({ showDrawer: true });

      findListSelector().vm.$emit('select', exclusionsMock[0]);
      findListSelector().vm.$emit('select', exclusionsMock[1]);
    });

    it('adds it to the list of selected exclusions', () => {
      expect(findListSelector().props('selectedItems')).toEqual(exclusionsMock);
    });

    describe('when Add exclusions button is clicked', () => {
      beforeEach(() => findAddExclusionsButton().vm.$emit('click'));

      it('emits the selected exclusions', () => {
        expect(wrapper.emitted('add')).toEqual([[exclusionsMock]]);
      });

      it('clears the list of selected exclusions', () => {
        expect(findListSelector().props('selectedItems')).toEqual([]);
      });
    });
  });
});
