import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { logError } from '~/lib/logger';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import CommitsMergeRequestButton from '~/projects/commits/components/commits_merge_request_button.vue';
import branchMergeRequestQuery from '~/projects/commits/graphql/queries/branch_merge_request.query.graphql';
import branchNamesQuery from '~/projects/commits/graphql/queries/branch_names.query.graphql';

Vue.use(VueApollo);

jest.mock('~/lib/logger');
jest.mock('~/sentry/sentry_browser_wrapper');

const mockMergeRequest = {
  __typename: 'MergeRequest',
  id: 'gid://gitlab/MergeRequest/1',
  webPath: '/gitlab-org/gitlab/-/merge_requests/1',
};

const mockSourcedMergeRequest = {
  __typename: 'MergeRequest',
  id: 'gid://gitlab/MergeRequest/2',
  webPath: '/gitlab-org/upstream/-/merge_requests/2',
};

const forkedFromProject = () => ({
  __typename: 'Project',
  id: 'gid://gitlab/Project/2',
});

const selfTarget = ({ createMergeRequestIn = true } = {}) => ({
  __typename: 'Project',
  id: 'gid://gitlab/Project/1',
  userPermissions: {
    __typename: 'ProjectPermissions',
    createMergeRequestIn,
  },
});

const upstreamTarget = ({ createMergeRequestIn = true } = {}) => ({
  __typename: 'Project',
  id: 'gid://gitlab/Project/2',
  userPermissions: {
    __typename: 'ProjectPermissions',
    createMergeRequestIn,
  },
});

const mergeRequestResponse = ({
  createMergeRequestFrom = true,
  createMergeRequestIn = true,
  mergeRequests = [],
  sourcedMergeRequests = [],
  forkedFrom = null,
  // Defaults to the project itself, mirroring its own permission, to match
  // the backend's non-fork behavior without cache-merge conflicts.
  defaultMergeRequestTarget = selfTarget({ createMergeRequestIn }),
} = {}) => ({
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      defaultMergeRequestTarget,
      userPermissions: {
        __typename: 'ProjectPermissions',
        createMergeRequestFrom,
        createMergeRequestIn,
      },
      mergeRequests: {
        __typename: 'MergeRequestConnection',
        nodes: mergeRequests,
      },
      sourcedMergeRequests:
        sourcedMergeRequests === null
          ? null
          : {
              __typename: 'MergeRequestConnection',
              nodes: sourcedMergeRequests,
            },
      forkedFrom,
    },
  },
});

const branchNamesResponse = (branchNames) => ({
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      repository: {
        __typename: 'Repository',
        branchNames,
      },
    },
  },
});

describe('CommitsMergeRequestButton', () => {
  let wrapper;
  let mergeRequestQueryHandler;
  let branchNamesQueryHandler;

  const createComponent = async ({
    props = {},
    mergeRequestHandler = jest.fn().mockResolvedValue(mergeRequestResponse()),
    branchNamesHandler = jest.fn().mockResolvedValue(branchNamesResponse(['feature'])),
  } = {}) => {
    mergeRequestQueryHandler = mergeRequestHandler;
    branchNamesQueryHandler = branchNamesHandler;

    wrapper = mountExtended(CommitsMergeRequestButton, {
      apolloProvider: createMockApollo([
        [branchMergeRequestQuery, mergeRequestQueryHandler],
        [branchNamesQuery, branchNamesQueryHandler],
      ]),
      provide: {
        projectFullPath: 'gitlab-org/gitlab',

        rootRef: 'main',
      },
      propsData: {
        currentRef: 'feature',
        refType: 'heads',
        ...props,
      },
    });

    await waitForPromises();
  };

  const findViewMergeRequestButton = () => wrapper.findByTestId('view-merge-request-button');
  const findCreateMergeRequestButton = () => wrapper.findByTestId('create-merge-request-button');

  const expectNoButtons = () => {
    expect(findCreateMergeRequestButton().exists()).toBe(false);
    expect(findViewMergeRequestButton().exists()).toBe(false);
  };

  describe('when an open merge request exists for the branch', () => {
    beforeEach(() => {
      return createComponent({
        mergeRequestHandler: jest
          .fn()
          .mockResolvedValue(mergeRequestResponse({ mergeRequests: [mockMergeRequest] })),
      });
    });

    it('renders the view merge request button linking to the merge request', () => {
      expect(findViewMergeRequestButton().attributes('href')).toBe(
        '/gitlab-org/gitlab/-/merge_requests/1',
      );
      expect(findViewMergeRequestButton().text()).toBe('View open merge request');
      expect(findViewMergeRequestButton().classes()).toContain('btn-default');
      expect(findViewMergeRequestButton().find('svg').exists()).toBe(false);
    });

    it('does not render the create merge request button', () => {
      expect(findCreateMergeRequestButton().exists()).toBe(false);
    });

    it('does not run the branch names query', () => {
      expect(branchNamesQueryHandler).not.toHaveBeenCalled();
    });

    it('emits the view merge request action', () => {
      expect(wrapper.emitted('merge-request-action').at(-1)).toEqual([
        {
          text: 'View open merge request',
          href: '/gitlab-org/gitlab/-/merge_requests/1',
          variant: 'default',
          testid: 'view-merge-request-link',
          buttonTestid: 'view-merge-request-button',
        },
      ]);
    });
  });

  describe('when no open merge request exists and the user has permissions', () => {
    beforeEach(() => {
      return createComponent();
    });

    it('queries with the correct variables', () => {
      expect(mergeRequestQueryHandler).toHaveBeenCalledWith({
        projectPath: 'gitlab-org/gitlab',
        sourceBranch: 'feature',
        targetBranch: 'main',
      });
    });

    it('renders the create merge request button with the new merge request path', () => {
      const button = findCreateMergeRequestButton();

      expect(button.text()).toBe('Create merge request');
      expect(button.classes()).toContain('btn-confirm');
      expect(button.attributes('href')).toBe(
        '/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature',
      );
    });

    it('does not render the view merge request button', () => {
      expect(findViewMergeRequestButton().exists()).toBe(false);
    });

    it('does not run the branch names query when the ref is a known branch', () => {
      expect(branchNamesQueryHandler).not.toHaveBeenCalled();
    });

    it('emits the create merge request action', () => {
      expect(wrapper.emitted('merge-request-action').at(-1)).toEqual([
        {
          text: 'Create merge request',
          href: '/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature',
          variant: 'confirm',
          testid: 'create-merge-request-link',
          buttonTestid: 'create-merge-request-button',
        },
      ]);
    });
  });

  describe.each`
    createMergeRequestFrom | createMergeRequestIn
    ${false}               | ${true}
    ${true}                | ${false}
    ${false}               | ${false}
  `(
    'when createMergeRequestFrom is $createMergeRequestFrom and createMergeRequestIn is $createMergeRequestIn',
    ({ createMergeRequestFrom, createMergeRequestIn }) => {
      beforeEach(() => {
        return createComponent({
          mergeRequestHandler: jest
            .fn()
            .mockResolvedValue(
              mergeRequestResponse({ createMergeRequestFrom, createMergeRequestIn }),
            ),
        });
      });

      it('renders no buttons', () => {
        expectNoButtons();
      });
    },
  );

  describe('when the project is a fork', () => {
    describe('with an open merge request sourced from the branch targeting the upstream project', () => {
      beforeEach(() => {
        return createComponent({
          mergeRequestHandler: jest.fn().mockResolvedValue(
            mergeRequestResponse({
              sourcedMergeRequests: [mockSourcedMergeRequest],
              forkedFrom: forkedFromProject(),
              defaultMergeRequestTarget: upstreamTarget(),
            }),
          ),
        });
      });

      it('renders the view merge request button linking to the sourced merge request', () => {
        expect(findViewMergeRequestButton().attributes('href')).toBe(
          '/gitlab-org/upstream/-/merge_requests/2',
        );
      });

      it('does not render the create merge request button', () => {
        expect(findCreateMergeRequestButton().exists()).toBe(false);
      });
    });

    describe('with an open sourced merge request and no permission to create merge requests upstream', () => {
      beforeEach(() => {
        return createComponent({
          mergeRequestHandler: jest.fn().mockResolvedValue(
            mergeRequestResponse({
              sourcedMergeRequests: [mockSourcedMergeRequest],
              forkedFrom: forkedFromProject(),
              defaultMergeRequestTarget: upstreamTarget({ createMergeRequestIn: false }),
            }),
          ),
        });
      });

      it('still renders the view merge request button', () => {
        expect(findViewMergeRequestButton().exists()).toBe(true);
      });
    });

    describe('without an open merge request', () => {
      beforeEach(() => {
        return createComponent({
          mergeRequestHandler: jest.fn().mockResolvedValue(
            mergeRequestResponse({
              forkedFrom: forkedFromProject(),
              defaultMergeRequestTarget: upstreamTarget(),
            }),
          ),
        });
      });

      it('renders the create merge request button targeting the upstream project', () => {
        expect(findCreateMergeRequestButton().attributes('href')).toBe(
          '/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature&merge_request%5Btarget_project_id%5D=2',
        );
      });
    });

    describe('when the default merge request target is the fork itself', () => {
      beforeEach(() => {
        return createComponent({
          mergeRequestHandler: jest.fn().mockResolvedValue(
            mergeRequestResponse({
              forkedFrom: forkedFromProject(),
              defaultMergeRequestTarget: selfTarget(),
            }),
          ),
        });
      });

      it('renders the create merge request button targeting the fork itself', () => {
        expect(findCreateMergeRequestButton().attributes('href')).toBe(
          '/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature',
        );
      });
    });

    describe('when the user cannot create merge requests in the upstream project', () => {
      beforeEach(() => {
        return createComponent({
          mergeRequestHandler: jest.fn().mockResolvedValue(
            mergeRequestResponse({
              forkedFrom: forkedFromProject(),
              defaultMergeRequestTarget: upstreamTarget({ createMergeRequestIn: false }),
            }),
          ),
        });
      });

      it('renders no buttons', () => {
        expectNoButtons();
      });
    });

    describe('when the user can create merge requests in the upstream project but not the fork', () => {
      beforeEach(() => {
        return createComponent({
          mergeRequestHandler: jest.fn().mockResolvedValue(
            mergeRequestResponse({
              createMergeRequestIn: false,
              forkedFrom: forkedFromProject(),
              defaultMergeRequestTarget: upstreamTarget(),
            }),
          ),
        });
      });

      it('renders the create merge request button', () => {
        expect(findCreateMergeRequestButton().exists()).toBe(true);
      });
    });

    describe('when the user cannot see the default merge request target', () => {
      beforeEach(() => {
        return createComponent({
          mergeRequestHandler: jest.fn().mockResolvedValue(
            mergeRequestResponse({
              forkedFrom: null,
              defaultMergeRequestTarget: null,
            }),
          ),
        });
      });

      it('gates on the fork itself and omits target_project_id', () => {
        expect(findCreateMergeRequestButton().attributes('href')).toBe(
          '/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature',
        );
      });
    });
  });

  describe('when a non-fork project has an open merge request targeting a non-default branch', () => {
    beforeEach(() => {
      return createComponent({
        mergeRequestHandler: jest.fn().mockResolvedValue(
          mergeRequestResponse({
            sourcedMergeRequests: [mockSourcedMergeRequest],
            forkedFrom: null,
          }),
        ),
      });
    });

    it('still renders the create merge request button', () => {
      expect(findCreateMergeRequestButton().attributes('href')).toBe(
        '/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature',
      );
    });

    it('does not render the view merge request button', () => {
      expect(findViewMergeRequestButton().exists()).toBe(false);
    });
  });

  describe('when the backend predates the sourcedMergeRequests field', () => {
    describe('with an open merge request within the fork', () => {
      beforeEach(() => {
        return createComponent({
          mergeRequestHandler: jest.fn().mockResolvedValue(
            mergeRequestResponse({
              mergeRequests: [mockMergeRequest],
              sourcedMergeRequests: null,
              defaultMergeRequestTarget: null,
              forkedFrom: forkedFromProject(),
            }),
          ),
        });
      });

      it('renders the view merge request button from the fork-local lookup', () => {
        expect(findViewMergeRequestButton().attributes('href')).toBe(
          '/gitlab-org/gitlab/-/merge_requests/1',
        );
      });
    });

    describe('without an open merge request', () => {
      beforeEach(() => {
        return createComponent({
          mergeRequestHandler: jest.fn().mockResolvedValue(
            mergeRequestResponse({
              sourcedMergeRequests: null,
              defaultMergeRequestTarget: null,
              forkedFrom: forkedFromProject(),
            }),
          ),
        });
      });

      it('keeps gating on the fork itself and omits target_project_id', () => {
        expect(findCreateMergeRequestButton().attributes('href')).toBe(
          '/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature',
        );
      });
    });
  });

  describe('when the ref type is unknown', () => {
    describe('and the ref is an existing branch', () => {
      beforeEach(() => {
        return createComponent({ props: { refType: '' } });
      });

      it('verifies the branch through the branch names query', () => {
        expect(branchNamesQueryHandler).toHaveBeenCalledWith({
          projectPath: 'gitlab-org/gitlab',
          ref: 'feature',
        });
      });

      it('renders the create merge request button', () => {
        expect(findCreateMergeRequestButton().exists()).toBe(true);
      });
    });

    describe('and multiple branches share a prefix with the ref', () => {
      beforeEach(() => {
        return createComponent({
          props: { refType: '' },
          branchNamesHandler: jest
            .fn()
            .mockResolvedValue(branchNamesResponse(['feature-1', 'feature-2', 'feature'])),
        });
      });

      it('renders the create merge request button when the exact branch is in the results', () => {
        expect(findCreateMergeRequestButton().exists()).toBe(true);
      });
    });

    describe('and the ref is not a branch (e.g. a commit SHA)', () => {
      beforeEach(() => {
        return createComponent({
          props: { currentRef: '1e292f8fedd741b75372e19097c76d327140c312', refType: '' },
          branchNamesHandler: jest.fn().mockResolvedValue(branchNamesResponse([])),
        });
      });

      it('renders no buttons', () => {
        expectNoButtons();
      });
    });

    describe('and the user lacks permissions', () => {
      beforeEach(() => {
        return createComponent({
          props: { refType: '' },
          mergeRequestHandler: jest
            .fn()
            .mockResolvedValue(mergeRequestResponse({ createMergeRequestFrom: false })),
        });
      });

      it('does not run the branch names query', () => {
        expect(branchNamesQueryHandler).not.toHaveBeenCalled();
      });
    });
  });

  describe.each`
    description                        | props
    ${'the ref is a tag'}              | ${{ refType: 'tags' }}
    ${'the ref is the default branch'} | ${{ currentRef: 'main' }}
    ${'there is no current ref'}       | ${{ currentRef: '' }}
  `('when $description', ({ props }) => {
    beforeEach(() => {
      return createComponent({ props });
    });

    it('skips the query and renders no buttons', () => {
      expect(mergeRequestQueryHandler).not.toHaveBeenCalled();
      expectNoButtons();
    });
  });

  describe('when the ref changes', () => {
    it('refetches with the new ref', async () => {
      await createComponent();

      await wrapper.setProps({ currentRef: 'other-branch' });
      await waitForPromises();

      expect(mergeRequestQueryHandler).toHaveBeenCalledTimes(2);
      expect(mergeRequestQueryHandler).toHaveBeenLastCalledWith({
        projectPath: 'gitlab-org/gitlab',
        sourceBranch: 'other-branch',
        targetBranch: 'main',
      });
    });

    it('hides the buttons after switching from a branch to a tag', async () => {
      await createComponent();

      expect(findCreateMergeRequestButton().exists()).toBe(true);

      await wrapper.setProps({ currentRef: 'v1.0.0', refType: 'tags' });
      await waitForPromises();

      expectNoButtons();
    });

    it('emits a null merge request action', async () => {
      await createComponent();

      await wrapper.setProps({ currentRef: 'v1.0.0', refType: 'tags' });
      await waitForPromises();

      expect(wrapper.emitted('merge-request-action').at(-1)).toEqual([null]);
    });
  });

  describe('when the query fails', () => {
    beforeEach(() => {
      return createComponent({
        mergeRequestHandler: jest.fn().mockRejectedValue(new Error('GraphQL error')),
      });
    });

    it('logs the error and reports it to Sentry', () => {
      expect(logError).toHaveBeenCalledWith(
        'Failed to fetch merge request data for the current ref.',
        expect.any(Error),
      );
      expect(Sentry.captureException).toHaveBeenCalled();
    });

    it('renders no buttons', () => {
      expectNoButtons();
    });
  });
});
