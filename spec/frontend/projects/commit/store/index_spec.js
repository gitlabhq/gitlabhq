import MockAdapter from 'axios-mock-adapter';
import { createTestingPinia } from '@pinia/testing';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { PROJECT_BRANCHES_ERROR } from '~/projects/commit/constants';
import { useCherryPickCommit } from '~/projects/commit/store/cherry_pick_commit';
import { useProjectCommit } from '~/projects/commit/store/project_commit';
import { useRevertCommit } from '~/projects/commit/store/revert_commit';
import mockData from '../mock_data';

jest.mock('~/alert');

describe('~/projects/commit/store', () => {
  let axiosMock;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    createTestingPinia({ stubActions: false });
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('useProjectCommit', () => {
    let store;

    beforeEach(() => {
      store = useProjectCommit();
    });

    describe('clearModal', () => {
      it('resets branch to defaultBranch', () => {
        store.$patch({ branch: '_main_', defaultBranch: '_default_branch_' });

        store.clearModal();

        expect(store.branch).toBe('_default_branch_');
      });
    });

    describe('fetchBranches', () => {
      it('sets isFetching to true while the request is in flight', () => {
        store.$patch({ branchesEndpoint: '/branches' });
        axiosMock.onGet('/branches').reply(() => new Promise(() => {}));

        store.fetchBranches();

        expect(store.isFetching).toBe(true);
      });

      describe('on success', () => {
        it('unshifts the current branch onto the response and resets isFetching', async () => {
          store.$patch({ branchesEndpoint: '/branches', branch: '_existing_branch_' });
          axiosMock
            .onGet('/branches')
            .replyOnce(HTTP_STATUS_OK, { Branches: ['_branch_1_', '_branch_2_'] });

          await store.fetchBranches();

          expect(store.branches).toEqual(['_existing_branch_', '_branch_1_', '_branch_2_']);
          expect(store.isFetching).toBe(false);
        });
      });

      describe('on error', () => {
        it('creates an alert with PROJECT_BRANCHES_ERROR and resets isFetching', async () => {
          store.$patch({ branchesEndpoint: '/branches' });
          axiosMock.onGet('/branches').replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

          await store.fetchBranches();

          expect(createAlert).toHaveBeenCalledWith({ message: PROJECT_BRANCHES_ERROR });
          expect(store.isFetching).toBe(false);
        });
      });
    });

    describe('setBranch', () => {
      it('sets branch', () => {
        store.setBranch('_changed_branch_');

        expect(store.branch).toBe('_changed_branch_');
      });
    });

    describe('setBranchesEndpoint', () => {
      it('sets branchesEndpoint', () => {
        store.setBranchesEndpoint('endpoint/2');

        expect(store.branchesEndpoint).toBe('endpoint/2');
      });
    });

    describe('joinedBranches', () => {
      it('returns a sorted list of branches', () => {
        store.$patch({ branches: mockData.mockBranches });

        expect(store.joinedBranches).toEqual(mockData.mockBranches.sort());
      });

      it('returns a uniq list of branches', () => {
        const branches = ['_branch_', '_branch_', '_different_branch'];
        store.$patch({ branches });

        expect(store.joinedBranches).toEqual(branches.slice(1));
      });
    });
  });

  describe('useCherryPickCommit', () => {
    let store;

    beforeEach(() => {
      store = useCherryPickCommit();
    });

    describe('setSelectedProject', () => {
      it('sets targetProjectId, resets branch, and fetches branches from the selected project', async () => {
        store.$patch({
          defaultBranch: '_default_',
          branchesEndpoint: '/fallback',
          projects: [{ id: 1, refsUrl: '/selected_project_refs' }],
        });
        axiosMock.onGet('/selected_project_refs').reply(() => new Promise(() => {}));

        store.setSelectedProject(1);
        await waitForPromises();

        expect(store.targetProjectId).toBe(1);
        expect(store.branch).toBe('_default_');
        expect(store.branchesEndpoint).toBe('/selected_project_refs');
        expect(axiosMock.history.get[0].url).toBe('/selected_project_refs');
      });
    });

    describe('sortedProjects', () => {
      it('returns a sorted list of projects', () => {
        store.$patch({ projects: mockData.mockProjects });

        expect(store.sortedProjects).toEqual(mockData.mockProjects.sort());
      });

      it('returns a uniq list of projects', () => {
        const projects = [
          { id: 1, name: '_project_', refsUrl: '/_project_/refs' },
          { id: 1, name: '_project_', refsUrl: '/_project_/refs' },
          { id: 3, name: '_some_other_project', refsUrl: '/_some_other_project/refs' },
        ];
        store.$patch({ projects });

        expect(store.sortedProjects).toHaveLength(2);
        expect(store.sortedProjects).toEqual(projects.slice(1));
      });
    });
  });

  describe('useRevertCommit', () => {
    it('exposes the same state shape as useProjectCommit', () => {
      const revertStore = useRevertCommit();
      const projectStore = useProjectCommit();

      expect(Object.keys(revertStore.$state).sort()).toEqual(
        Object.keys(projectStore.$state).sort(),
      );
    });
  });

  describe('modal stores', () => {
    it('keeps cherry-pick and revert state isolated on the shared Pinia instance', () => {
      const cherryPickStore = useCherryPickCommit();
      const revertStore = useRevertCommit();

      cherryPickStore.$patch({
        endpoint: '/cherry-pick',
        branch: '_cherry_branch_',
        defaultBranch: '_cherry_default_',
        targetProjectId: '_target_project_',
      });
      revertStore.$patch({
        endpoint: '/revert',
        branch: '_revert_branch_',
        defaultBranch: '_revert_default_',
      });

      cherryPickStore.clearModal();
      revertStore.clearModal();

      expect(cherryPickStore.endpoint).toBe('/cherry-pick');
      expect(cherryPickStore.branch).toBe('_cherry_default_');
      expect(cherryPickStore.targetProjectId).toBe('_target_project_');
      expect(revertStore.endpoint).toBe('/revert');
      expect(revertStore.branch).toBe('_revert_default_');
    });
  });
});
