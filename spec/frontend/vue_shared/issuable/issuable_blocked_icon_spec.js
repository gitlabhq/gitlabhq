import { GlIcon, GlLink, GlPopover, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssuableBlockedIcon from '~/vue_shared/components/issuable_blocked_icon/issuable_blocked_icon.vue';
import { blockingIssuablesQueries } from '~/vue_shared/components/issuable_blocked_icon/constants';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import { truncate } from '~/lib/utils/text_utility';
import {
  mockIssue,
  mockEpic,
  mockBlockingIssue1,
  mockBlockingIssue2,
  mockBlockingEpic1,
  mockBlockingIssuablesResponse1,
  mockBlockingIssuablesResponse2,
  mockBlockingIssuablesResponse3,
  mockBlockedIssue1,
  mockBlockedIssue2,
  mockBlockedEpic1,
  mockBlockingEpicIssuablesResponse1,
} from '../../boards/mock_data';

describe('IssuableBlockedIcon', () => {
  let wrapper;
  let mockApollo;

  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const findGlPopover = () => wrapper.findComponent(GlPopover);
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findPopoverTitle = () => wrapper.findByTestId('popover-title');
  const findIssuableTitle = () => wrapper.findByTestId('issuable-title');
  const findHiddenBlockingCount = () => wrapper.findByTestId('hidden-blocking-count');
  const findViewAllIssuableLink = () => wrapper.findByTestId('view-all-issues');

  const waitForApollo = async () => {
    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  const mouseenter = async () => {
    findGlIcon().vm.$emit('mouseenter');

    await nextTick();
    await waitForApollo();
  };

  const createWrapperWithApollo = ({
    item = mockBlockedIssue1,
    blockingIssuablesSpy = jest.fn().mockResolvedValue(mockBlockingIssuablesResponse1),
    issuableItem = mockIssue,
    issuableType = TYPE_ISSUE,
  } = {}) => {
    mockApollo = createMockApollo([
      [blockingIssuablesQueries[issuableType].query, blockingIssuablesSpy],
    ]);

    Vue.use(VueApollo);
    wrapper = extendedWrapper(
      mount(IssuableBlockedIcon, {
        apolloProvider: mockApollo,
        propsData: {
          item: {
            ...issuableItem,
            ...item,
          },
          uniqueId: 'uniqueId',
          issuableType,
        },
        attachTo: document.body,
      }),
    );
  };

  const createWrapper = ({
    item = {},
    queries = {},
    data = {},
    loading = false,
    mockIssuable = mockIssue,
    issuableType = TYPE_ISSUE,
  } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(IssuableBlockedIcon, {
        propsData: {
          item: {
            ...mockIssuable,
            ...item,
          },
          uniqueId: 'uniqueid',
          issuableType,
        },
        data() {
          return {
            ...data,
          };
        },
        mocks: {
          $apollo: {
            queries: {
              blockingIssuables: { loading },
              ...queries,
            },
          },
        },
        stubs: {
          GlPopover,
        },
        attachTo: document.body,
      }),
    );
  };

  it.each`
    mockIssuable | issuableType  | expectedIcon
    ${mockIssue} | ${TYPE_ISSUE} | ${'entity-blocked'}
    ${mockEpic}  | ${TYPE_EPIC}  | ${'entity-blocked'}
  `(
    'should render blocked icon for $issuableType',
    ({ mockIssuable, issuableType, expectedIcon }) => {
      createWrapper({
        mockIssuable,
        issuableType,
      });

      expect(findGlIcon().exists()).toBe(true);
      const icon = findGlIcon();
      expect(icon.exists()).toBe(true);
      expect(icon.props('name')).toBe(expectedIcon);
    },
  );

  it('should display a loading spinner while loading', () => {
    createWrapper({ loading: true });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('should not query for blocking issuables by default', () => {
    createWrapperWithApollo();

    expect(findGlPopover().text()).not.toContain(mockBlockingIssue1.title);
  });

  describe('on mouseenter on blocked icon', () => {
    it.each`
      item                 | issuableType  | mockBlockingIssuable  | issuableItem | blockingIssuablesSpy
      ${mockBlockedIssue1} | ${TYPE_ISSUE} | ${mockBlockingIssue1} | ${mockIssue} | ${jest.fn().mockResolvedValue(mockBlockingIssuablesResponse1)}
      ${mockBlockedEpic1}  | ${TYPE_EPIC}  | ${mockBlockingEpic1}  | ${mockEpic}  | ${jest.fn().mockResolvedValue(mockBlockingEpicIssuablesResponse1)}
    `(
      'should query for blocking issuables and render the result for $issuableType',
      async ({ item, issuableType, issuableItem, mockBlockingIssuable, blockingIssuablesSpy }) => {
        createWrapperWithApollo({
          item,
          issuableType,
          issuableItem,
          blockingIssuablesSpy,
        });

        expect(findGlPopover().text()).not.toContain(mockBlockingIssuable.title);

        await mouseenter();

        expect(findGlPopover().exists()).toBe(true);
        expect(findIssuableTitle().text()).toContain(mockBlockingIssuable.title);
        expect(wrapper.vm.skip).toBe(true);
      },
    );

    it('should emit "blocking-issuables-error" event on query error', async () => {
      const mockError = new Error('mayday');
      createWrapperWithApollo({ blockingIssuablesSpy: jest.fn().mockRejectedValue(mockError) });

      await mouseenter();

      const [
        [
          {
            message,
            error: { networkError },
          },
        ],
      ] = wrapper.emitted('blocking-issuables-error');
      expect(message).toBe('Failed to fetch blocking issues');
      expect(networkError).toBe(mockError);
    });

    describe('with a single blocking issue', () => {
      beforeEach(async () => {
        createWrapperWithApollo();

        await mouseenter();
      });

      it('should render a title of the issuable', () => {
        expect(findIssuableTitle().text()).toBe(mockBlockingIssue1.title);
      });

      it('should render issuable reference and link to the issuable', () => {
        const formattedRef = mockBlockingIssue1.reference.split('/')[1];

        expect(findGlLink().text()).toBe(formattedRef);
        expect(findGlLink().attributes('href')).toBe(mockBlockingIssue1.webUrl);
      });

      it('should render popover title with correct blocking issuable count', () => {
        expect(findPopoverTitle().text()).toBe('Blocked by 1 issue');
      });
    });

    describe('when issue has a long title', () => {
      it('should render a truncated title', async () => {
        createWrapperWithApollo({
          blockingIssuablesSpy: jest.fn().mockResolvedValue(mockBlockingIssuablesResponse2),
        });

        await mouseenter();

        const truncatedTitle = truncate(
          mockBlockingIssue2.title,
          wrapper.vm.$options.textTruncateWidth,
        );
        expect(findIssuableTitle().text()).toBe(truncatedTitle);
      });
    });

    describe('with more than three blocking issues', () => {
      beforeEach(async () => {
        createWrapperWithApollo({
          item: mockBlockedIssue2,
          blockingIssuablesSpy: jest.fn().mockResolvedValue(mockBlockingIssuablesResponse3),
        });

        await mouseenter();
      });

      it('should render popover title with correct blocking issuable count', () => {
        expect(findPopoverTitle().text()).toBe('Blocked by 4 issues');
      });

      it('should render the number of hidden blocking issuables', () => {
        expect(findHiddenBlockingCount().text()).toBe('+ 1 more issue');
      });

      it('should link to the blocked issue page at the related issue anchor', () => {
        expect(findViewAllIssuableLink().text()).toBe('View all blocking issues');
        expect(findViewAllIssuableLink().attributes('href')).toBe(
          `${mockBlockedIssue2.webUrl}#related-issues`,
        );
      });
    });
  });
});
