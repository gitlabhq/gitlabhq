import Vue from 'vue';
import { trimText } from 'helpers/text_helper';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import NavDropdownButton from '~/ide/components/nav_dropdown_button.vue';
import { createStore } from '~/ide/stores';

describe('NavDropdown', () => {
  const TEST_BRANCH_ID = 'lorem-ipsum-dolar';
  const TEST_MR_ID = '12345';
  let store;
  let vm;

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    vm.$destroy();
  });

  const createComponent = (props = {}) => {
    vm = mountComponentWithStore(Vue.extend(NavDropdownButton), { props, store });
    vm.$mount();
  };

  const findIcon = (name) => vm.$el.querySelector(`[data-testid="${name}-icon"]`);
  const findMRIcon = () => findIcon('merge-request');
  const findBranchIcon = () => findIcon('branch');

  describe('normal', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders empty placeholders, if state is falsey', () => {
      expect(trimText(vm.$el.textContent)).toEqual('- -');
    });

    it('renders branch name, if state has currentBranchId', (done) => {
      vm.$store.state.currentBranchId = TEST_BRANCH_ID;

      vm.$nextTick()
        .then(() => {
          expect(trimText(vm.$el.textContent)).toEqual(`${TEST_BRANCH_ID} -`);
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders mr id, if state has currentMergeRequestId', (done) => {
      vm.$store.state.currentMergeRequestId = TEST_MR_ID;

      vm.$nextTick()
        .then(() => {
          expect(trimText(vm.$el.textContent)).toEqual(`- !${TEST_MR_ID}`);
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders branch and mr, if state has both', (done) => {
      vm.$store.state.currentBranchId = TEST_BRANCH_ID;
      vm.$store.state.currentMergeRequestId = TEST_MR_ID;

      vm.$nextTick()
        .then(() => {
          expect(trimText(vm.$el.textContent)).toEqual(`${TEST_BRANCH_ID} !${TEST_MR_ID}`);
        })
        .then(done)
        .catch(done.fail);
    });

    it('shows icons', () => {
      expect(findBranchIcon()).toBeTruthy();
      expect(findMRIcon()).toBeTruthy();
    });
  });

  describe('with showMergeRequests false', () => {
    beforeEach(() => {
      createComponent({ showMergeRequests: false });
    });

    it('shows single empty placeholder, if state is falsey', () => {
      expect(trimText(vm.$el.textContent)).toEqual('-');
    });

    it('shows only branch icon', () => {
      expect(findBranchIcon()).toBeTruthy();
      expect(findMRIcon()).toBe(null);
    });
  });
});
