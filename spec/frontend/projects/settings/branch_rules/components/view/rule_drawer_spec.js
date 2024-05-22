import { GlDrawer } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import RuleDrawer from '~/projects/settings/branch_rules/components/view/rule_drawer.vue';
import { allowedToMergeDrawerProps } from 'ee_else_ce_jest/projects/settings/branch_rules/components/view/mock_data';

jest.mock('~/lib/utils/dom_utils', () => ({ getContentWrapperHeight: jest.fn() }));

const TEST_HEADER_HEIGHT = '123px';

describe('Edit Rule Drawer', () => {
  let wrapper;

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findCancelButton = () => wrapper.findByText('Cancel');
  const findHeader = () => wrapper.find('h2');
  const findSaveButton = () => wrapper.findByTestId('save-allowed-to-merge');

  const createComponent = (props = allowedToMergeDrawerProps) => {
    wrapper = shallowMountExtended(RuleDrawer, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    getContentWrapperHeight.mockReturnValue(TEST_HEADER_HEIGHT);
    createComponent();
  });

  describe('rendering', () => {
    it('renders the correct title when adding', () => {
      expect(findHeader().text()).toBe('Edit allowed to merge');
    });

    it('renders drawer with props', () => {
      expect(findDrawer().props()).toMatchObject({
        open: false,
        headerHeight: TEST_HEADER_HEIGHT,
        zIndex: DRAWER_Z_INDEX,
      });
    });
  });

  it('disables the save button when no changes are made', () => {
    expect(findSaveButton().attributes('disabled')).toBeDefined();
  });

  it('emits an edit rule event when save button is clicked', () => {
    findSaveButton().vm.$emit('click');
    expect(wrapper.emitted('editRule')).toHaveLength(1);
  });

  it('emits a close event when cancel button is clicked', () => {
    findCancelButton().vm.$emit('click');
    expect(wrapper.emitted('close')).toHaveLength(1);
  });
});
