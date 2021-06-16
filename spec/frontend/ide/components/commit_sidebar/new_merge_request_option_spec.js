import Vue from 'vue';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import { projectData, branches } from 'jest/ide/mock_data';
import NewMergeRequestOption from '~/ide/components/commit_sidebar/new_merge_request_option.vue';
import { PERMISSION_CREATE_MR } from '~/ide/constants';
import { createStore } from '~/ide/stores';
import {
  COMMIT_TO_CURRENT_BRANCH,
  COMMIT_TO_NEW_BRANCH,
} from '~/ide/stores/modules/commit/constants';

describe('create new MR checkbox', () => {
  let store;
  let vm;

  const setMR = () => {
    vm.$store.state.currentMergeRequestId = '1';
    vm.$store.state.projects[store.state.currentProjectId].mergeRequests[
      store.state.currentMergeRequestId
    ] = { foo: 'bar' };
  };

  const setPermissions = (permissions) => {
    store.state.projects[store.state.currentProjectId].userPermissions = permissions;
  };

  const createComponent = ({ currentBranchId = 'main', createNewBranch = false } = {}) => {
    const Component = Vue.extend(NewMergeRequestOption);

    vm = createComponentWithStore(Component, store);

    vm.$store.state.commit.commitAction = createNewBranch
      ? COMMIT_TO_NEW_BRANCH
      : COMMIT_TO_CURRENT_BRANCH;

    vm.$store.state.currentBranchId = currentBranchId;

    store.state.projects.abcproject.branches[currentBranchId] = branches.find(
      (branch) => branch.name === currentBranchId,
    );

    return vm.$mount();
  };

  const findInput = () => vm.$el.querySelector('input[type="checkbox"]');
  const findLabel = () => vm.$el.querySelector('.js-ide-commit-new-mr');

  beforeEach(() => {
    store = createStore();

    store.state.currentProjectId = 'abcproject';

    const proj = JSON.parse(JSON.stringify(projectData));
    proj.userPermissions[PERMISSION_CREATE_MR] = true;
    Vue.set(store.state.projects, 'abcproject', proj);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('for default branch', () => {
    describe('is rendered when pushing to a new branch', () => {
      beforeEach(() => {
        createComponent({
          currentBranchId: 'main',
          createNewBranch: true,
        });
      });

      it('has NO new MR', () => {
        expect(vm.$el.textContent).not.toBe('');
      });

      it('has new MR', (done) => {
        setMR();

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.textContent).not.toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('is NOT rendered when pushing to the same branch', () => {
      beforeEach(() => {
        createComponent({
          currentBranchId: 'main',
          createNewBranch: false,
        });
      });

      it('has NO new MR', () => {
        expect(vm.$el.textContent).toBe('');
      });

      it('has new MR', (done) => {
        setMR();

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.textContent).toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('for protected branch', () => {
    describe('when user does not have the write access', () => {
      beforeEach(() => {
        createComponent({
          currentBranchId: 'protected/no-access',
        });
      });

      it('is rendered if MR does not exists', () => {
        expect(vm.$el.textContent).not.toBe('');
      });

      it('is rendered if MR exists', (done) => {
        setMR();

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.textContent).not.toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('when user has the write access', () => {
      beforeEach(() => {
        createComponent({
          currentBranchId: 'protected/access',
        });
      });

      it('is rendered if MR does not exist', () => {
        expect(vm.$el.textContent).not.toBe('');
      });

      it('is hidden if MR exists', (done) => {
        setMR();

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.textContent).toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('for regular branch', () => {
    beforeEach(() => {
      createComponent({
        currentBranchId: 'regular',
      });
    });

    it('is rendered if no MR exists', () => {
      expect(vm.$el.textContent).not.toBe('');
    });

    it('is hidden if MR exists', (done) => {
      setMR();

      vm.$nextTick()
        .then(() => {
          expect(vm.$el.textContent).toBe('');
        })
        .then(done)
        .catch(done.fail);
    });

    it('shows enablded checkbox', () => {
      expect(findLabel().classList.contains('is-disabled')).toBe(false);
      expect(findInput().disabled).toBe(false);
    });
  });

  describe('when user cannot create MR', () => {
    beforeEach(() => {
      setPermissions({ [PERMISSION_CREATE_MR]: false });

      createComponent({ currentBranchId: 'regular' });
    });

    it('disabled checkbox', () => {
      expect(findLabel().classList.contains('is-disabled')).toBe(true);
      expect(findInput().disabled).toBe(true);
    });
  });

  it('dispatches toggleShouldCreateMR when clicking checkbox', () => {
    createComponent({
      currentBranchId: 'regular',
    });
    const el = vm.$el.querySelector('input[type="checkbox"]');
    jest.spyOn(vm.$store, 'dispatch').mockImplementation(() => {});
    el.dispatchEvent(new Event('change'));

    expect(vm.$store.dispatch.mock.calls).toEqual(
      expect.arrayContaining([['commit/toggleShouldCreateMR', expect.any(Object)]]),
    );
  });
});
