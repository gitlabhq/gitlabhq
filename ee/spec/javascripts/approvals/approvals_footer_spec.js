import Vue from 'vue';
import pendingAvatarSvg from 'ee_icons/_icon_dotted_circle.svg';
import ApprovalsFooter from 'ee/vue_merge_request_widget/components/approvals/approvals_footer.vue';
import { TEST_HOST } from 'spec/test_constants';

describe('Approvals Footer Component', () => {
  let vm;
  const initialData = {
    mr: {
      state: 'readyToMerge',
    },
    service: {},
    userCanApprove: false,
    userHasApproved: true,
    approvedBy: [],
    approvalsLeft: 1,
    pendingAvatarSvg,
  };

  beforeEach(() => {
    setFixtures('<div id="mock-container"></div>');
    const ApprovalsFooterComponent = Vue.extend(ApprovalsFooter);

    vm = new ApprovalsFooterComponent({
      el: '#mock-container',
      propsData: initialData,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should correctly set component props', () => {
    Object.keys(vm).forEach(propKey => {
      if (initialData[propKey]) {
        expect(vm[propKey]).toBe(initialData[propKey]);
      }
    });
  });

  describe('Computed properties', () => {
    it('should correctly set showUnapproveButton when the user can unapprove', () => {
      expect(vm.showUnapproveButton).toBeTruthy();
      vm.mr.state = 'merged';
      expect(vm.showUnapproveButton).toBeFalsy();
    });

    it('should correctly set showUnapproveButton when the user can not unapprove', done => {
      vm.userCanApprove = true;

      Vue.nextTick(() => {
        expect(vm.showUnapproveButton).toBe(false);
        done();
      });
    });
  });

  describe('approvers list', () => {
    it('shows link to member avatar for for each approver', done => {
      vm.approvedBy.push({
        user: {
          avatar_url: `${TEST_HOST}/dummy.jpg`,
        },
      });

      Vue.nextTick(() => {
        const memberImage = document.querySelector('.approvers-list img');
        expect(memberImage.src).toMatch(/dummy\.jpg$/);
        done();
      });
    });
  });
});
