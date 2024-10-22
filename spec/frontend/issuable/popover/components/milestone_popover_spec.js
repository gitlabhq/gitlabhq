import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlIcon, GlSkeletonLoader, GlProgressBar, GlBadge } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeDate } from 'helpers/fake_date';

import milestoneQuery from '~/issuable/popover/queries/milestone.query.graphql';
import MilestonePopover from '~/issuable/popover/components/milestone_popover.vue';

describe('Milestone Popover', () => {
  const mockGroup = {
    id: 'gid://gitlab/Group/1',
    fullPath: 'gitlab-org',
    __typename: 'Group',
  };
  const mockProject = {
    id: 'gid://gitlab/Project/1',
    fullPath: 'gitlab-org/gitlab-test',
    __typename: 'Project',
  };
  const mockStats = {
    closedIssuesCount: 2,
    totalIssuesCount: 3,
    __typename: 'MilestoneStats',
  };

  const mockMilestoneResponse = {
    data: {
      milestone: {
        id: 'gid://gitlab/Milestone/65',
        title: '16.11',
        expired: false,
        upcoming: false,
        createdAt: '2024-04-08T07:40:06Z',
        startDate: '2024-04-01',
        dueDate: '2024-04-30',
        groupMilestone: false,
        group: null,
        projectMilestone: true,
        project: mockProject,
        state: 'active',
        stats: mockStats,
        __typename: 'Milestone',
      },
    },
  };

  const mockMilestone = mockMilestoneResponse.data.milestone;
  let wrapper;

  Vue.use(VueApollo);

  const mountComponent = ({
    queryResponse = jest.fn().mockResolvedValue(mockMilestoneResponse),
  } = {}) => {
    wrapper = shallowMountExtended(MilestonePopover, {
      apolloProvider: createMockApollo([[milestoneQuery, queryResponse]]),
      propsData: {
        target: document.createElement('a'),
        milestoneId: '65',
        cachedTitle: '%16.11',
      },
    });
  };

  const findStateBadge = () => wrapper.findComponent(GlBadge);
  const findMilestoneTimeframe = () => wrapper.findByTestId('milestone-timeframe');
  const findMilestoneProgress = () => wrapper.findByTestId('milestone-progress');

  describe('while popover is loading', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows icon and text', () => {
      const milestoneEl = wrapper.findByTestId('milestone-label');
      const milestoneIcon = milestoneEl.findComponent(GlIcon);

      expect(milestoneEl.exists()).toBe(true);
      expect(milestoneIcon.exists()).toBe(true);
      expect(milestoneIcon.props('name')).toBe('milestone');
      expect(milestoneEl.text()).toBe('Milestone');
    });

    it('shows skeleton-loader', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });

    it('shows cached title', () => {
      expect(wrapper.find('h5').text()).toBe('16.11');
    });

    it('does not show state badge or dates', () => {
      expect(findStateBadge().exists()).toBe(false);
      expect(findMilestoneTimeframe().exists()).toBe(false);
    });
  });

  describe('when popover contents are loaded', () => {
    // Set current date to 10th April 2024
    useFakeDate(2024, 3, 10);

    beforeEach(async () => {
      mountComponent();

      await waitForPromises();
    });

    it.each`
      expired  | upcoming | state       | expectedVariant | expectedText
      ${false} | ${false} | ${'closed'} | ${'danger'}     | ${'Closed'}
      ${true}  | ${false} | ${'active'} | ${'warning'}    | ${'Expired'}
      ${false} | ${true}  | ${'active'} | ${'muted'}      | ${'Upcoming'}
      ${false} | ${false} | ${'active'} | ${'success'}    | ${'Active'}
    `(
      'shows state badge with variant $expectedVariant and text $expectedText',
      async ({ expired, upcoming, state, expectedVariant, expectedText }) => {
        mountComponent({
          queryResponse: jest.fn().mockResolvedValue({
            data: {
              milestone: {
                ...mockMilestone,
                expired,
                upcoming,
                state,
              },
            },
          }),
        });

        await waitForPromises();

        expect(findStateBadge().props('variant')).toBe(expectedVariant);
        expect(findStateBadge().text()).toBe(expectedText);
      },
    );

    it.each`
      startDate       | dueDate         | expectedText
      ${'2024-04-01'} | ${'2024-04-30'} | ${'Apr 1 – 30, 2024'}
      ${'2024-03-01'} | ${null}         | ${'Started Mar 1, 2024'}
      ${'2024-04-20'} | ${null}         | ${'Starts Apr 20, 2024'}
      ${null}         | ${'2024-04-20'} | ${'Ends Apr 20, 2024'}
      ${null}         | ${'2024-02-20'} | ${'Ended Feb 20, 2024'}
    `(
      'shows timeframe text when startDate is $startDate and dueDate is $dueDate',
      async ({ startDate, dueDate, expectedText }) => {
        mountComponent({
          queryResponse: jest.fn().mockResolvedValue({
            data: {
              milestone: {
                ...mockMilestone,
                startDate,
                dueDate,
              },
            },
          }),
        });

        await waitForPromises();

        expect(findMilestoneTimeframe().text()).toBe(`· ${expectedText}`);
      },
    );

    it('shows progress bar and percentage completion', () => {
      const progressEl = findMilestoneProgress();
      const progressBar = progressEl.findComponent(GlProgressBar);
      expect(progressBar.attributes()).toMatchObject({
        value: '66',
        variant: 'primary',
      });
      expect(progressEl.find('span').text()).toBe('66% complete');
    });

    it('does not show progress when there are no issues associated with the milestone', async () => {
      mountComponent({
        queryResponse: jest.fn().mockResolvedValue({
          data: {
            milestone: {
              ...mockMilestone,
              stats: {
                closedIssuesCount: 0,
                totalIssuesCount: 0,
                __typename: 'MilestoneStats',
              },
            },
          },
        }),
      });

      await waitForPromises();

      expect(findMilestoneProgress().exists()).toBe(false);
    });

    it.each`
      groupMilestone | projectMilestone | group        | project        | iconName     | fullPath
      ${false}       | ${true}          | ${null}      | ${mockProject} | ${'project'} | ${mockProject.fullPath}
      ${true}        | ${false}         | ${mockGroup} | ${null}        | ${'group'}   | ${mockGroup.fullPath}
    `(
      'shows milestone parent icon as $iconName and full path',
      async ({ groupMilestone, group, projectMilestone, project, iconName, fullPath }) => {
        mountComponent({
          queryResponse: jest.fn().mockResolvedValue({
            data: {
              milestone: {
                ...mockMilestone,
                groupMilestone,
                projectMilestone,
                group,
                project,
              },
            },
          }),
        });

        await waitForPromises();

        const pathEl = wrapper.findByTestId('milestone-path');
        const parentTypeIcon = pathEl.findComponent(GlIcon);

        expect(parentTypeIcon.props('name')).toBe(iconName);
        expect(pathEl.find('span').text()).toBe(fullPath);
      },
    );
  });
});
