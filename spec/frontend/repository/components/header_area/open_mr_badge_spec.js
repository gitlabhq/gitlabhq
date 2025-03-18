import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlBadge, GlPopover, GlSkeletonLoader } from '@gitlab/ui';
import OpenMrBadge from '~/repository/components/header_area/open_mr_badge.vue';
import getOpenMrCountsForBlobPath from '~/repository/queries/open_mr_count.query.graphql';
import getOpenMrsForBlobPath from '~/repository/queries/open_mrs.query.graphql';
import MergeRequestListItem from '~/repository/components/header_area/merge_request_list_item.vue';
import { logError } from '~/lib/logger';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { openMRQueryResult, zeroOpenMRQueryResult, openMRsDetailResult } from './mock_data';

Vue.use(VueApollo);
jest.mock('~/lib/logger');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('OpenMrBadge', () => {
  let wrapper;
  let openMrsCountQueryHandler;
  let openMrsQueryHandler;

  const defaultProps = {
    projectPath: 'group/project',
    blobPath: 'path/to/file.js',
  };

  function createComponent(
    props = {},
    mockResolver = openMRQueryResult,
    mrDetailResolver = openMRsDetailResult,
  ) {
    openMrsCountQueryHandler = mockResolver;
    openMrsQueryHandler = mrDetailResolver;

    const mockApollo = createMockApollo([
      [getOpenMrCountsForBlobPath, mockResolver],
      [getOpenMrsForBlobPath, mrDetailResolver],
    ]);

    wrapper = shallowMount(OpenMrBadge, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        currentRef: 'main',
      },
      apolloProvider: mockApollo,
    });
  }

  const findPopover = () => wrapper.findComponent(GlPopover);
  const findAllMergeRequestItems = () => wrapper.findAllComponents(MergeRequestListItem);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);

  describe('rendering', () => {
    it('does not render badge when query is loading', () => {
      createComponent();
      expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
    });

    it('does not render badge when there are no open MRs', async () => {
      createComponent({}, zeroOpenMRQueryResult);
      await waitForPromises();

      expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
    });
  });

  describe('computed properties', () => {
    useFakeDate();

    beforeEach(() => {
      createComponent({});
    });

    it('computes queryVariables correctly', () => {
      expect(openMrsCountQueryHandler).toHaveBeenCalledWith({
        blobPath: 'path/to/file.js',
        createdAfter: '2020-06-07',
        projectPath: 'group/project',
        targetBranch: ['main'],
      });
    });
  });

  describe('apollo query', () => {
    describe('fetchOpenMrCount', () => {
      it('fetch mr count and render badge correctly', async () => {
        createComponent();
        await waitForPromises();

        const badge = wrapper.findComponent(GlBadge);
        expect(badge.exists()).toBe(true);
        expect(badge.props('variant')).toBe('success');
        expect(badge.props('icon')).toBe('merge-request');
        expect(wrapper.text()).toBe('3 open');
      });

      it('handles errors when fetching MR count', async () => {
        const mockError = new Error();
        createComponent({}, jest.fn().mockRejectedValueOnce(mockError));
        await waitForPromises();

        expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
        expect(logError).toHaveBeenCalledWith(
          'Failed to fetch merge request count. See exception details for more information.',
          mockError,
        );
        expect(Sentry.captureException).toHaveBeenCalledWith(mockError);
      });
    });

    describe('fetchOpenMrs', () => {
      it('fetches MRs and updates data', async () => {
        createComponent();
        findPopover().vm.$emit('show');
        await waitForPromises();

        expect(openMrsQueryHandler).toHaveBeenCalledWith({
          blobPath: 'path/to/file.js',
          createdAfter: '2020-06-07',
          projectPath: 'group/project',
          targetBranch: ['main'],
        });

        expect(findAllMergeRequestItems().length).toEqual(2);
        expect(findLoader().exists()).toBe(false);
      });

      it('handles errors when fetching MRs', async () => {
        const mockError = new Error('Failed to fetch MRs');
        const errorResolver = jest.fn().mockRejectedValue(mockError);

        createComponent({}, openMRQueryResult, errorResolver);
        await waitForPromises();

        findPopover().vm.$emit('show');
        await waitForPromises();

        expect(logError).toHaveBeenCalledWith(
          'Failed to fetch merge requests. See exception details for more information.',
          mockError,
        );
        expect(Sentry.captureException).toHaveBeenCalledWith(mockError);
      });
    });
  });

  describe('popover functionality', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets correct props on the popover', () => {
      expect(findPopover().props()).toMatchObject({
        target: 'open-mr-badge',
        boundary: 'viewport',
        placement: 'bottomleft',
      });
    });

    it('shows skeleton loader when loading MRs', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('calls fetchOpenMrs when popover is shown', async () => {
      await waitForPromises();
      findPopover().vm.$emit('show');
      await nextTick();

      expect(openMrsQueryHandler).toHaveBeenCalled();
    });
  });
});
