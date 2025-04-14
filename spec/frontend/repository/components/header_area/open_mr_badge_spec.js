import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdown, GlSkeletonLoader, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import OpenMrBadge from '~/repository/components/header_area/open_mr_badge.vue';
import getOpenMrCountsForBlobPath from '~/repository/queries/open_mr_count.query.graphql';
import getOpenMrsForBlobPath from '~/repository/queries/open_mrs.query.graphql';
import MergeRequestListItem from '~/repository/components/header_area/merge_request_list_item.vue';
import { logError } from '~/lib/logger';
import { visitUrl } from '~/lib/utils/url_utility';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { openMRQueryResult, zeroOpenMRQueryResult, openMRsDetailResult } from './mock_data';

Vue.use(VueApollo);
jest.mock('~/lib/logger');
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/url_utility');

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

    wrapper = shallowMountExtended(OpenMrBadge, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        currentRef: 'main',
      },
      apolloProvider: mockApollo,
      stubs: {
        GlDisclosureDropdown: stubComponent(GlDisclosureDropdown, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });
  }

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findOpenMrBadge = () => wrapper.findByTestId('open-mr-badge');
  const findAllMergeRequestItems = () => wrapper.findAllComponents(MergeRequestListItem);
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);

  describe('rendering', () => {
    it('does not render badge when query is loading', () => {
      createComponent();
      expect(findOpenMrBadge().exists()).toBe(false);
    });

    it('does not render badge when there are no open MRs', async () => {
      createComponent({}, zeroOpenMRQueryResult);
      await waitForPromises();

      expect(findOpenMrBadge().exists()).toBe(false);
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
      it('fetch mr count ands renders the dropdown + badge when data is available', async () => {
        createComponent();
        await waitForPromises();

        const badge = findOpenMrBadge();
        expect(badge.exists()).toBe(true);
        expect(badge.props('variant')).toBe('success');
        expect(badge.props('icon')).toBe('merge-request');
        expect(badge.attributes('title')).toBe(
          'Open merge requests created in the past 30 days that target this branch and modify this file.',
        );
        expect(badge.text()).toBe('3 Open');
      });

      it('handles errors when fetching MR count', async () => {
        const mockError = new Error();
        createComponent({}, jest.fn().mockRejectedValueOnce(mockError));
        await waitForPromises();

        expect(findDropdown().exists()).toBe(false);
        expect(logError).toHaveBeenCalledWith(
          'Failed to fetch merge request count. See exception details for more information.',
          mockError,
        );
        expect(Sentry.captureException).toHaveBeenCalledWith(mockError);
      });
    });

    describe('fetchOpenMrs', () => {
      it('shows loader when loading MRs', async () => {
        createComponent();
        await waitForPromises();
        findDropdown().vm.$emit('shown');
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

        findDropdown().vm.$emit('shown');
        await waitForPromises();

        expect(logError).toHaveBeenCalledWith(
          'Failed to fetch merge requests. See exception details for more information.',
          mockError,
        );
        expect(Sentry.captureException).toHaveBeenCalledWith(mockError);
      });
    });
  });

  describe('dropdown functionality', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('sets correct props on the dropdown', () => {
      expect(findDropdown().props()).toMatchObject({
        fluidWidth: true,
        loading: false,
        placement: 'bottom-end',
      });
    });

    it('shows skeleton loader when loading MRs', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('calls fetchOpenMrs when dropdown is shown', async () => {
      await waitForPromises();
      findDropdown().vm.$emit('shown');
      await nextTick();

      expect(openMrsQueryHandler).toHaveBeenCalled();
    });

    it('calls visitUrl with correct URL when dropdown item is clicked', async () => {
      findDropdown().vm.$emit('shown');
      await waitForPromises();

      const firstDropdownItem = findDropdownItems().at(0);
      firstDropdownItem.vm.$emit('action');

      expect(visitUrl).toHaveBeenCalledWith('https://gitlab.com/root/project/-/merge_requests/123');
    });
  });
});
