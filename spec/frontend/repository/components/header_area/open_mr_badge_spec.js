import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlBadge } from '@gitlab/ui';
import OpenMrBadge from '~/repository/components/header_area/open_mr_badge.vue';
import getOpenMrCountsForBlobPath from '~/repository/queries/open_mr_counts.query.graphql';
import { logError } from '~/lib/logger';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { openMRQueryResult, zeroOpenMRQueryResult } from './mock_data';

Vue.use(VueApollo);
jest.mock('~/lib/logger');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('OpenMrBadge', () => {
  let wrapper;
  let requestHandler;

  const defaultProps = {
    projectPath: 'group/project',
    blobPath: 'path/to/file.js',
  };

  function createComponent(props = {}, mockResolver = openMRQueryResult) {
    requestHandler = mockResolver;
    const mockApollo = createMockApollo([[getOpenMrCountsForBlobPath, mockResolver]]);

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

    it('renders badge when when there are open MRs', async () => {
      createComponent();
      await waitForPromises();

      const badge = wrapper.findComponent(GlBadge);
      expect(badge.exists()).toBe(true);
      expect(badge.props('variant')).toBe('success');
      expect(badge.props('icon')).toBe('merge-request');
      expect(wrapper.text()).toBe('3 open');
    });
  });

  describe('computed properties', () => {
    useFakeDate();

    beforeEach(() => {
      createComponent({});
    });

    it('computes queryVariables correctly', () => {
      expect(requestHandler).toHaveBeenCalledWith({
        blobPath: 'path/to/file.js',
        createdAfter: '2020-06-07',
        projectPath: 'group/project',
        targetBranch: ['main'],
      });
    });
  });

  describe('apollo query', () => {
    it('handles apollo error correctly', async () => {
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
});
