import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { RouterLinkStub } from '@vue/test-utils';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RepositoryOverflowMenu from '~/repository/components/header_area/repository_overflow_menu.vue';
import PermalinkDropdownItem from '~/repository/components/header_area/permalink_dropdown_item.vue';
import permalinkPathQuery from '~/repository/queries/permalink_path.query.graphql';
import { logError } from '~/lib/logger';
import {
  mockPermalinkResult,
  mockRootPermalinkResult,
} from 'jest/repository/components/header_area/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

Vue.use(VueApollo);
jest.mock('~/lib/logger');
jest.mock('~/sentry/sentry_browser_wrapper');

const path = 'cmd';
const projectPath = 'gitlab-org/gitlab-shell';
const ref = '5059017dea6e834f2f86fc670703ca36cbae98d6';

const defaultMockRoute = {
  params: {
    path: '/-/tree',
  },
  meta: {
    refType: '',
  },
  query: {
    ref_type: '',
  },
  name: 'treePathDecoded',
};

describe('RepositoryOverflowMenu', () => {
  let wrapper;
  let permalinkQueryHandler;
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findDropdownItemWithText = (text) =>
    findDropdownItems().wrappers.find((x) => x.props('item').text === text);
  const findCompareItem = () => findDropdownItemWithText('Compare');

  const findPermalinkItem = () => wrapper.findComponent(PermalinkDropdownItem);

  const createComponent = ({
    route = {},
    provide = {},
    props = {},
    mockResolver = mockPermalinkResult,
  } = {}) => {
    permalinkQueryHandler = mockResolver;
    const mockApollo = createMockApollo([[permalinkPathQuery, mockResolver]]);

    return shallowMountExtended(RepositoryOverflowMenu, {
      provide: {
        comparePath: null,
        ...provide,
      },
      propsData: {
        fullPath: projectPath,
        path,
        currentRef: ref,
        ...props,
      },
      stubs: {
        RouterLink: RouterLinkStub,
      },
      mocks: {
        $route: {
          ...defaultMockRoute,
          ...route,
        },
      },
      apolloProvider: mockApollo,
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders the component', () => {
    expect(wrapper.exists()).toBe(true);
  });

  describe('computed properties', () => {
    it('computes queryVariables correctly', () => {
      expect(permalinkQueryHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab-shell',
        path: 'cmd',
        ref: '5059017dea6e834f2f86fc670703ca36cbae98d6',
      });
    });

    describe('Compare item', () => {
      it('does not render Compare button for root ref', () => {
        wrapper = createComponent({ route: { params: { path: '/-/tree/new-branch-3' } } });
        expect(findCompareItem()).toBeUndefined();
      });

      it('renders Compare button for non-root ref', () => {
        wrapper = createComponent({
          route: {
            params: { path: '/-/tree/new-branch-3' },
          },
          provide: { comparePath: 'test/project/-/compare?from=master&to=new-branch-3' },
        });
        expect(findCompareItem().exists()).toBe(true);
        expect(findCompareItem().props('item')).toMatchObject({
          href: 'test/project/-/compare?from=master&to=new-branch-3',
        });
      });

      it('does not render compare button when comparePath is not provided', () => {
        wrapper = createComponent();
        expect(findCompareItem()).toBeUndefined();
      });
    });

    describe('Permalink item', () => {
      it('renders Permalink button for non-root route', async () => {
        wrapper = createComponent();
        await waitForPromises();
        expect(findPermalinkItem().props('permalinkPath')).toBe(
          '/gitlab-org/gitlab-shell/-/tree/5059017dea6e834f2f86fc670703ca36cbae98d6/cmd',
        );
        expect(findPermalinkItem().props('source')).toBe('repository');
      });

      it('renders Permalink button with projectPath for root route', async () => {
        wrapper = createComponent({
          props: { path: undefined },
          mockResolver: mockRootPermalinkResult,
        });
        await waitForPromises();
        expect(findPermalinkItem().props('permalinkPath')).toBe(
          '/gitlab-org/gitlab-shell/-/tree/5059017dea6e834f2f86fc670703ca36cbae98d6/',
        );
        expect(findPermalinkItem().props('source')).toBe('repository');
      });

      it('handles errors when fetching permalinkPath', async () => {
        const mockError = new Error();
        wrapper = createComponent({ mockResolver: jest.fn().mockRejectedValueOnce(mockError) });
        await waitForPromises();

        expect(findPermalinkItem().exists()).toBe(false);
        expect(logError).toHaveBeenCalledWith(
          'Failed to fetch permalink. See exception details for more information.',
          mockError,
        );
        expect(Sentry.captureException).toHaveBeenCalledWith(mockError);
      });
    });
  });
});
