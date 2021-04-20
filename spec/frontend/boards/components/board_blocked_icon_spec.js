import { GlIcon, GlLink, GlPopover, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BoardBlockedIcon from '~/boards/components/board_blocked_icon.vue';
import { blockingIssuablesQueries, issuableTypes } from '~/boards/constants';
import { truncate } from '~/lib/utils/text_utility';
import {
  mockIssue,
  mockBlockingIssue1,
  mockBlockingIssue2,
  mockBlockingIssuablesResponse1,
  mockBlockingIssuablesResponse2,
  mockBlockingIssuablesResponse3,
  mockBlockedIssue1,
  mockBlockedIssue2,
} from '../mock_data';

describe('BoardBlockedIcon', () => {
  let wrapper;
  let mockApollo;

  const findGlIcon = () => wrapper.find(GlIcon);
  const findGlPopover = () => wrapper.find(GlPopover);
  const findGlLink = () => wrapper.find(GlLink);
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

    await wrapper.vm.$nextTick();
    await waitForApollo();
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const createWrapperWithApollo = ({
    item = mockBlockedIssue1,
    blockingIssuablesSpy = jest.fn().mockResolvedValue(mockBlockingIssuablesResponse1),
  } = {}) => {
    mockApollo = createMockApollo([
      [blockingIssuablesQueries[issuableTypes.issue].query, blockingIssuablesSpy],
    ]);

    Vue.use(VueApollo);
    wrapper = extendedWrapper(
      mount(BoardBlockedIcon, {
        apolloProvider: mockApollo,
        propsData: {
          item: {
            ...mockIssue,
            ...item,
          },
          uniqueId: 'uniqueId',
          issuableType: issuableTypes.issue,
        },
        attachTo: document.body,
      }),
    );
  };

  const createWrapper = ({ item = {}, queries = {}, data = {}, loading = false } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(BoardBlockedIcon, {
        propsData: {
          item: {
            ...mockIssue,
            ...item,
          },
          uniqueId: 'uniqueid',
          issuableType: issuableTypes.issue,
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

  it('should render blocked icon', () => {
    createWrapper();

    expect(findGlIcon().exists()).toBe(true);
  });

  it('should display a loading spinner while loading', () => {
    createWrapper({ loading: true });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('should not query for blocking issuables by default', async () => {
    createWrapperWithApollo();

    expect(findGlPopover().text()).not.toContain(mockBlockingIssue1.title);
  });

  describe('on mouseenter on blocked icon', () => {
    it('should query for blocking issuables and render the result', async () => {
      createWrapperWithApollo();

      expect(findGlPopover().text()).not.toContain(mockBlockingIssue1.title);

      await mouseenter();

      expect(findGlPopover().exists()).toBe(true);
      expect(findIssuableTitle().text()).toContain(mockBlockingIssue1.title);
      expect(wrapper.vm.skip).toBe(true);
    });

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

      it('should render a title of the issuable', async () => {
        expect(findIssuableTitle().text()).toBe(mockBlockingIssue1.title);
      });

      it('should render issuable reference and link to the issuable', async () => {
        const formattedRef = mockBlockingIssue1.reference.split('/')[1];

        expect(findGlLink().text()).toBe(formattedRef);
        expect(findGlLink().attributes('href')).toBe(mockBlockingIssue1.webUrl);
      });

      it('should render popover title with correct blocking issuable count', async () => {
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

      it('matches the snapshot', () => {
        expect(wrapper.html()).toMatchSnapshot();
      });

      it('should render popover title with correct blocking issuable count', async () => {
        expect(findPopoverTitle().text()).toBe('Blocked by 4 issues');
      });

      it('should render the number of hidden blocking issuables', () => {
        expect(findHiddenBlockingCount().text()).toBe('+ 1 more issue');
      });

      it('should link to the blocked issue page at the related issue anchor', async () => {
        expect(findViewAllIssuableLink().text()).toBe('View all blocking issues');
        expect(findViewAllIssuableLink().attributes('href')).toBe(
          `${mockBlockedIssue2.webUrl}#related-issues`,
        );
      });
    });
  });
});
