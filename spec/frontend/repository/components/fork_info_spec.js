import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader, GlIcon, GlLink, GlSprintf, GlButton, GlLoadingIcon } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_INFO } from '~/alert';

import ForkInfo, { i18n } from '~/repository/components/fork_info.vue';
import ConflictsModal from '~/repository/components/fork_sync_conflicts_modal.vue';
import forkDetailsQuery from '~/repository/queries/fork_details.query.graphql';
import syncForkMutation from '~/repository/mutations/sync_fork.mutation.graphql';
import eventHub from '~/repository/event_hub';
import {
  POLLING_INTERVAL_DEFAULT,
  POLLING_INTERVAL_BACKOFF,
  FORK_UPDATED_EVENT,
} from '~/repository/constants';
import { propsForkInfo } from '../mock_data';

jest.mock('~/alert');

describe('ForkInfo component', () => {
  let wrapper;
  let mockForkDetailsQuery;
  const forkInfoError = new Error('Something went wrong');
  const projectId = 'gid://gitlab/Project/1';
  const showMock = jest.fn();

  Vue.use(VueApollo);

  const waitForPolling = async (interval = POLLING_INTERVAL_DEFAULT) => {
    jest.advanceTimersByTime(interval);
    await waitForPromises();
  };

  const mockResolvedForkDetailsQuery = (
    forkDetails = { ahead: 3, behind: 7, isSyncing: false, hasConflicts: false },
  ) => {
    mockForkDetailsQuery.mockResolvedValue({
      data: {
        project: { id: projectId, forkDetails },
      },
    });
  };

  const createSyncForkDetailsData = (
    forkDetails = { ahead: 3, behind: 7, isSyncing: false, hasConflicts: false },
  ) => {
    return {
      data: {
        projectSyncFork: { details: forkDetails, errors: [] },
      },
    };
  };

  const createComponent = (props = {}, mutationData = {}) => {
    wrapper = shallowMountExtended(ForkInfo, {
      apolloProvider: createMockApollo([
        [forkDetailsQuery, mockForkDetailsQuery],
        [syncForkMutation, jest.fn().mockResolvedValue(createSyncForkDetailsData(mutationData))],
      ]),
      propsData: { ...propsForkInfo, ...props },
      stubs: {
        GlSprintf,
        GlButton,
        ConflictsModal: stubComponent(ConflictsModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
          methods: { show: showMock },
        }),
      },
    });
    return waitForPromises();
  };

  const findLink = () => wrapper.findComponent(GlLink);
  const findSkeleton = () => wrapper.findComponent(GlSkeletonLoader);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findUpdateForkButton = () => wrapper.findByTestId('update-fork-button');
  const findCreateMrButton = () => wrapper.findByTestId('create-mr-button');
  const findViewMrButton = () => wrapper.findByTestId('view-mr-button');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDivergenceMessage = () => wrapper.findByTestId('divergence-message');
  const findInaccessibleMessage = () => wrapper.findByTestId('inaccessible-project');
  const findCompareLinks = () => findDivergenceMessage().findAllComponents(GlLink);

  const startForkUpdate = async () => {
    findUpdateForkButton().vm.$emit('click');
    await waitForPromises();
  };

  beforeEach(() => {
    mockForkDetailsQuery = jest.fn();
    mockResolvedForkDetailsQuery();
  });

  it('displays a skeleton while loading data', () => {
    createComponent();
    expect(findSkeleton().exists()).toBe(true);
  });

  it('does not display skeleton when data is loaded', async () => {
    await createComponent();
    expect(findSkeleton().exists()).toBe(false);
  });

  it('renders fork icon', async () => {
    await createComponent();
    expect(findIcon().exists()).toBe(true);
  });

  it('queries the data when sourceName is present', async () => {
    await createComponent();
    expect(mockForkDetailsQuery).toHaveBeenCalled();
  });

  it('does not query the data when sourceName is empty', async () => {
    await createComponent({ sourceName: null });
    expect(mockForkDetailsQuery).not.toHaveBeenCalled();
  });

  it('renders inaccessible message when fork source is not available', async () => {
    await createComponent({ sourceName: '' });
    const message = findInaccessibleMessage();
    expect(message.exists()).toBe(true);
    expect(message.text()).toBe(i18n.inaccessibleProject);
  });

  it('shows source project name with a link to a repo', async () => {
    await createComponent();
    const link = findLink();
    expect(link.text()).toBe(propsForkInfo.sourceName);
    expect(link.attributes('href')).toBe(propsForkInfo.sourcePath);
  });

  it('renders Create MR Button with correct path', async () => {
    await createComponent();
    expect(findCreateMrButton().attributes('href')).toBe(propsForkInfo.createMrPath);
  });

  it('renders View MR Button with correct path', async () => {
    const viewMrPath = 'path/to/view/mr';
    await createComponent({ viewMrPath });
    expect(findViewMrButton().attributes('href')).toBe(viewMrPath);
  });

  it('does not render create MR button if create MR path is blank', async () => {
    await createComponent({ createMrPath: '' });
    expect(findCreateMrButton().exists()).toBe(false);
  });

  it('renders alert with error message when request fails', async () => {
    mockForkDetailsQuery.mockRejectedValue(forkInfoError);
    await createComponent({});
    expect(createAlert).toHaveBeenCalledWith({
      message: i18n.error,
      captureError: true,
      error: forkInfoError,
    });
  });

  describe('Unknown divergence', () => {
    it('renders unknown divergence message when divergence is unknown', async () => {
      mockResolvedForkDetailsQuery({
        ahead: null,
        behind: null,
        isSyncing: false,
        hasConflicts: false,
      });
      await createComponent({});
      expect(findDivergenceMessage().text()).toBe(i18n.unknown);
    });

    it('renders Update Fork button', async () => {
      mockResolvedForkDetailsQuery({
        ahead: null,
        behind: null,
        isSyncing: false,
        hasConflicts: false,
      });
      await createComponent({});
      expect(findUpdateForkButton().exists()).toBe(true);
      expect(findUpdateForkButton().text()).toBe(i18n.updateFork);
    });
  });

  describe('Up to date divergence', () => {
    beforeEach(async () => {
      mockResolvedForkDetailsQuery({ ahead: 0, behind: 0, isSyncing: false, hasConflicts: false });
      await createComponent({}, { ahead: 0, behind: 0, isSyncing: false, hasConflicts: false });
    });

    it('renders up to date message when fork is up to date', () => {
      expect(findDivergenceMessage().text()).toBe(i18n.upToDate);
    });

    it('does not render Update Fork button', () => {
      expect(findUpdateForkButton().exists()).toBe(false);
    });
  });

  describe('Limited visibility project', () => {
    beforeEach(async () => {
      mockResolvedForkDetailsQuery(null);
      await createComponent({}, null);
    });

    it('renders limited visibility message when forkDetails are empty', () => {
      expect(findDivergenceMessage().text()).toBe(i18n.limitedVisibility);
    });

    it('does not render Update Fork button', () => {
      expect(findUpdateForkButton().exists()).toBe(false);
    });
  });

  describe('User cannot sync the branch', () => {
    beforeEach(async () => {
      mockResolvedForkDetailsQuery({ ahead: 0, behind: 7, isSyncing: false, hasConflicts: false });
      await createComponent(
        { canSyncBranch: false },
        { ahead: 0, behind: 7, isSyncing: false, hasConflicts: false },
      );
    });

    it('does not render Update Fork button', () => {
      expect(findUpdateForkButton().exists()).toBe(false);
    });
  });

  describe.each([
    {
      ahead: 7,
      behind: 3,
      message: '3 commits behind, 7 commits ahead of the upstream repository.',
      firstLink: propsForkInfo.behindComparePath,
      secondLink: propsForkInfo.aheadComparePath,
      hasUpdateButton: true,
      hasCreateMrButton: true,
    },
    {
      ahead: 7,
      behind: 0,
      message: '7 commits ahead of the upstream repository.',
      firstLink: propsForkInfo.aheadComparePath,
      secondLink: '',
      hasUpdateButton: false,
      hasCreateMrButton: true,
    },
    {
      ahead: 0,
      behind: 3,
      message: '3 commits behind the upstream repository.',
      firstLink: propsForkInfo.behindComparePath,
      secondLink: '',
      hasUpdateButton: true,
      hasCreateMrButton: false,
    },
  ])(
    'renders correct divergence message for ahead: $ahead, behind: $behind divergence commits',
    ({ ahead, behind, message, firstLink, secondLink, hasUpdateButton, hasCreateMrButton }) => {
      beforeEach(async () => {
        mockResolvedForkDetailsQuery({ ahead, behind, isSyncing: false, hasConflicts: false });
        await createComponent({});
      });

      it('displays correct text', () => {
        expect(findDivergenceMessage().text()).toBe(message);
      });

      it('adds correct links', () => {
        const links = findCompareLinks();
        expect(links.at(0).attributes('href')).toBe(firstLink);

        if (secondLink) {
          expect(links.at(1).attributes('href')).toBe(secondLink);
        }
      });

      it('renders Update Fork button when fork is behind', () => {
        expect(findUpdateForkButton().exists()).toBe(hasUpdateButton);
        if (hasUpdateButton) {
          expect(findUpdateForkButton().text()).toBe(i18n.updateFork);
        }
      });

      it('renders Create Merge Request button when fork is ahead', () => {
        expect(findCreateMrButton().exists()).toBe(hasCreateMrButton);
        if (hasCreateMrButton) {
          expect(findCreateMrButton().text()).toBe(i18n.createMergeRequest);
        }
      });
    },
  );

  describe('when sync is not possible due to conflicts', () => {
    it('Opens Conflicts Modal', async () => {
      mockResolvedForkDetailsQuery({ ahead: 7, behind: 3, isSyncing: false, hasConflicts: true });
      await createComponent({});
      findUpdateForkButton().vm.$emit('click');
      expect(showMock).toHaveBeenCalled();
    });
  });

  describe('projectSyncFork mutation', () => {
    it('changes button to have loading state', async () => {
      await createComponent({}, { ahead: 0, behind: 3, isSyncing: true, hasConflicts: false });
      mockResolvedForkDetailsQuery({ ahead: 0, behind: 3, isSyncing: false, hasConflicts: false });
      expect(findLoadingIcon().exists()).toBe(false);
      await startForkUpdate();
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('polling', () => {
    beforeEach(async () => {
      await createComponent({}, { ahead: 0, behind: 3, isSyncing: true, hasConflicts: false });
      mockResolvedForkDetailsQuery({ ahead: 0, behind: 3, isSyncing: true, hasConflicts: false });
    });

    it('fetches data on the initial load', () => {
      expect(mockForkDetailsQuery).toHaveBeenCalledTimes(1);
    });

    it('starts polling after sync button is clicked', async () => {
      await startForkUpdate();
      await waitForPolling();
      expect(mockForkDetailsQuery).toHaveBeenCalledTimes(2);

      await waitForPolling(POLLING_INTERVAL_DEFAULT * POLLING_INTERVAL_BACKOFF);
      expect(mockForkDetailsQuery).toHaveBeenCalledTimes(3);
    });

    it('stops polling once sync is finished', async () => {
      mockResolvedForkDetailsQuery({ ahead: 0, behind: 0, isSyncing: false, hasConflicts: false });
      await startForkUpdate();
      await waitForPolling();
      expect(mockForkDetailsQuery).toHaveBeenCalledTimes(2);
      await waitForPolling(POLLING_INTERVAL_DEFAULT * POLLING_INTERVAL_BACKOFF);
      expect(mockForkDetailsQuery).toHaveBeenCalledTimes(2);
      await nextTick();
    });
  });

  describe('once fork is updated', () => {
    beforeEach(async () => {
      await createComponent({}, { ahead: 0, behind: 3, isSyncing: true, hasConflicts: false });
      mockResolvedForkDetailsQuery({ ahead: 0, behind: 0, isSyncing: false, hasConflicts: false });
    });

    it('shows info alert once the fork is updated', async () => {
      await startForkUpdate();
      await waitForPolling();
      expect(createAlert).toHaveBeenCalledWith({
        message: i18n.successMessage,
        variant: VARIANT_INFO,
      });
    });

    it('emits fork:updated event to eventHub', async () => {
      jest.spyOn(eventHub, '$emit').mockImplementation();
      await startForkUpdate();
      await waitForPolling();
      expect(eventHub.$emit).toHaveBeenCalledWith(FORK_UPDATED_EVENT);
    });

    it('hides update fork button', async () => {
      jest.spyOn(eventHub, '$emit').mockImplementation();
      await startForkUpdate();
      await waitForPolling();
      expect(findUpdateForkButton().exists()).toBe(false);
    });
  });
});
