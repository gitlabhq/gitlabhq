import { trimText } from 'helpers/text_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NavDropdownButton from '~/ide/components/nav_dropdown_button.vue';
import { createStore } from '~/ide/stores';

describe('NavDropdownButton component', () => {
  const TEST_BRANCH_ID = 'lorem-ipsum-dolar';
  const TEST_MR_ID = '12345';
  let wrapper;

  const createComponent = ({ props = {}, state = {} } = {}) => {
    const store = createStore();
    store.replaceState(state);
    wrapper = shallowMountExtended(NavDropdownButton, { propsData: props, store });
  };

  const findMRIcon = () => wrapper.findByTestId('merge-request-icon');
  const findBranchIcon = () => wrapper.findByTestId('branch-icon');

  describe('normal', () => {
    it('renders empty placeholders, if state is falsey', () => {
      createComponent();

      expect(trimText(wrapper.text())).toBe('- -');
    });

    it('renders branch name, if state has currentBranchId', () => {
      createComponent({ state: { currentBranchId: TEST_BRANCH_ID } });

      expect(trimText(wrapper.text())).toBe(`${TEST_BRANCH_ID} -`);
    });

    it('renders mr id, if state has currentMergeRequestId', () => {
      createComponent({ state: { currentMergeRequestId: TEST_MR_ID } });

      expect(trimText(wrapper.text())).toBe(`- !${TEST_MR_ID}`);
    });

    it('renders branch and mr, if state has both', () => {
      createComponent({
        state: { currentBranchId: TEST_BRANCH_ID, currentMergeRequestId: TEST_MR_ID },
      });

      expect(trimText(wrapper.text())).toBe(`${TEST_BRANCH_ID} !${TEST_MR_ID}`);
    });

    it('shows icons', () => {
      createComponent();

      expect(findBranchIcon().exists()).toBe(true);
      expect(findMRIcon().exists()).toBe(true);
    });
  });

  describe('when showMergeRequests=false', () => {
    beforeEach(() => {
      createComponent({ props: { showMergeRequests: false } });
    });

    it('shows single empty placeholder, if state is falsey', () => {
      expect(trimText(wrapper.text())).toBe('-');
    });

    it('shows only branch icon', () => {
      expect(findBranchIcon().exists()).toBe(true);
      expect(findMRIcon().exists()).toBe(false);
    });
  });
});
