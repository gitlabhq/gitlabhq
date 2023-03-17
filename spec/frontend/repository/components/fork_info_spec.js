import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader, GlIcon, GlLink, GlSprintf, GlButton, GlLoadingIcon } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';

import ForkInfo, { i18n } from '~/repository/components/fork_info.vue';
import ConflictsModal from '~/repository/components/fork_sync_conflicts_modal.vue';
import forkDetailsQuery from '~/repository/queries/fork_details.query.graphql';
import syncForkMutation from '~/repository/mutations/sync_fork.mutation.graphql';
import { propsForkInfo } from '../mock_data';

jest.mock('~/alert');

describe('ForkInfo component', () => {
  let wrapper;
  let mockResolver;
  const forkInfoError = new Error('Something went wrong');
  const projectId = 'gid://gitlab/Project/1';
  const showMock = jest.fn();
  const synchronizeFork = true;

  Vue.use(VueApollo);

  const createForkDetailsData = (
    forkDetails = { ahead: 3, behind: 7, isSyncing: false, hasConflicts: false },
  ) => {
    return {
      data: {
        project: { id: projectId, forkDetails },
      },
    };
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

  const createComponent = (props = {}, data = {}, mutationData = {}, isRequestFailed = false) => {
    mockResolver = isRequestFailed
      ? jest.fn().mockRejectedValue(forkInfoError)
      : jest.fn().mockResolvedValue(createForkDetailsData(data));

    wrapper = shallowMountExtended(ForkInfo, {
      apolloProvider: createMockApollo([
        [forkDetailsQuery, mockResolver],
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
      provide: {
        glFeatures: {
          synchronizeFork,
        },
      },
    });
    return waitForPromises();
  };

  const findLink = () => wrapper.findComponent(GlLink);
  const findSkeleton = () => wrapper.findComponent(GlSkeletonLoader);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findUpdateForkButton = () => wrapper.findComponent(GlButton);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDivergenceMessage = () => wrapper.findByTestId('divergence-message');
  const findInaccessibleMessage = () => wrapper.findByTestId('inaccessible-project');
  const findCompareLinks = () => findDivergenceMessage().findAllComponents(GlLink);

  it('displays a skeleton while loading data', async () => {
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
    expect(mockResolver).toHaveBeenCalled();
  });

  it('does not query the data when sourceName is empty', async () => {
    await createComponent({ sourceName: null });
    expect(mockResolver).not.toHaveBeenCalled();
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

  describe('Unknown divergence', () => {
    beforeEach(async () => {
      await createComponent(
        {},
        { ahead: null, behind: null, isSyncing: false, hasConflicts: false },
      );
    });

    it('renders unknown divergence message when divergence is unknown', async () => {
      expect(findDivergenceMessage().text()).toBe(i18n.unknown);
    });

    it('renders Update Fork button', async () => {
      expect(findUpdateForkButton().exists()).toBe(true);
      expect(findUpdateForkButton().text()).toBe(i18n.sync);
    });
  });

  describe('Up to date divergence', () => {
    beforeEach(async () => {
      await createComponent({}, { ahead: 0, behind: 0, isSyncing: false, hasConflicts: false });
    });

    it('renders up to date message when fork is up to date', async () => {
      expect(findDivergenceMessage().text()).toBe(i18n.upToDate);
    });

    it('does not render Update Fork button', async () => {
      expect(findUpdateForkButton().exists()).toBe(false);
    });
  });

  describe('Limited visibility project', () => {
    beforeEach(async () => {
      await createComponent({}, null);
    });

    it('renders limited visibility messsage when forkDetails are empty', async () => {
      expect(findDivergenceMessage().text()).toBe(i18n.limitedVisibility);
    });

    it('does not render Update Fork button', async () => {
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
      hasButton: true,
    },
    {
      ahead: 7,
      behind: 0,
      message: '7 commits ahead of the upstream repository.',
      firstLink: propsForkInfo.aheadComparePath,
      secondLink: '',
      hasButton: false,
    },
    {
      ahead: 0,
      behind: 3,
      message: '3 commits behind the upstream repository.',
      firstLink: propsForkInfo.behindComparePath,
      secondLink: '',
      hasButton: true,
    },
  ])(
    'renders correct divergence message for ahead: $ahead, behind: $behind divergence commits',
    ({ ahead, behind, message, firstLink, secondLink, hasButton }) => {
      beforeEach(async () => {
        await createComponent({}, { ahead, behind, isSyncing: false, hasConflicts: false });
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
        expect(findUpdateForkButton().exists()).toBe(hasButton);
        if (hasButton) {
          expect(findUpdateForkButton().text()).toBe(i18n.sync);
        }
      });
    },
  );

  describe('when sync is not possible due to conflicts', () => {
    it('opens Conflicts Modal', async () => {
      await createComponent({}, { ahead: 7, behind: 3, isSyncing: false, hasConflicts: true });
      findUpdateForkButton().vm.$emit('click');
      expect(showMock).toHaveBeenCalled();
    });
  });

  describe('projectSyncFork mutation', () => {
    it('changes button to have loading state', async () => {
      await createComponent(
        {},
        { ahead: 0, behind: 3, isSyncing: false, hasConflicts: false },
        { ahead: 0, behind: 3, isSyncing: true, hasConflicts: false },
      );
      expect(findLoadingIcon().exists()).toBe(false);
      findUpdateForkButton().vm.$emit('click');
      await waitForPromises();
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  it('renders alert with error message when request fails', async () => {
    await createComponent({}, {}, true);
    expect(createAlert).toHaveBeenCalledWith({
      message: i18n.error,
      captureError: true,
      error: forkInfoError,
    });
  });
});
