import { GlSprintf } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import WikiHeader from '~/wikis/components/wiki_header.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import wikiPageQuery from '~/wikis/graphql/wiki_page.query.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { queryVariables, wikiPageQueryMockData } from '../notes/mock_data';

Vue.use(VueApollo);
describe('wikis/components/wiki_header', () => {
  let wrapper;
  let fakeApollo;

  const mockToastShow = jest.fn();

  function buildWrapper(provide = {}, mockQueryData = {}) {
    fakeApollo = createMockApollo([
      [
        wikiPageQuery,
        jest.fn().mockResolvedValue({
          data: {
            wikiPage: wikiPageQueryMockData,
            ...mockQueryData,
          },
        }),
      ],
    ]);

    wrapper = shallowMountExtended(WikiHeader, {
      apolloProvider: fakeApollo,
      provide: {
        pageHeading: 'Wiki page heading',
        queryVariables,
        isPageTemplate: false,
        isEditingPath: false,
        showEditButton: true,
        wikiUrl: 'http://wiki.url',
        editButtonUrl: 'http://edit.url',
        lastVersion: '2024-06-03T01:53:28.000Z',
        pageVersion: {
          author_name: 'Test author',
          authored_date: '2024-06-03T01:53:28.000Z',
        },
        pagePersisted: true,
        authorUrl: 'http://author.url',
        ...provide,
      },
      stubs: {
        GlSprintf,
        TimeAgo,
        PageHeading,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  }

  const findPageHeading = () => wrapper.findByTestId('page-heading');
  const findEditButton = () => wrapper.findByTestId('wiki-edit-button');
  const findSubscribeButton = () => wrapper.findByTestId('wiki-subscribe-button');
  const findLastVersion = () => wrapper.findByTestId('wiki-page-last-version');
  const findSidebarToggle = () => wrapper.findByTestId('wiki-sidebar-toggle');

  describe('renders', () => {
    beforeEach(() => {
      buildWrapper();
    });

    it('renders correct page heading', () => {
      expect(findPageHeading().text()).toBe('Wiki page heading');
    });

    it('renders edit button if url is set', () => {
      expect(findEditButton().exists()).toBe(true);

      buildWrapper({ showEditButton: false });

      expect(findEditButton().exists()).toBe(false);
    });

    it('renders last version information', () => {
      expect(findLastVersion().text()).toBe('Last edited by Test author Jun 3, 2024');

      buildWrapper({ lastVersion: false });

      expect(findLastVersion().exists()).toBe(false);
    });

    it('renders sidebar toggle', () => {
      expect(findSidebarToggle().exists()).toBe(true);
      expect(findSidebarToggle().attributes('aria-label')).toBe('Toggle sidebar');
    });
  });

  describe('subscribe button functionality', () => {
    let mutateSpy;

    beforeEach(async () => {
      buildWrapper();
      mutateSpy = jest.spyOn(wrapper.vm.$apollo.provider.defaultClient, 'mutate');

      await nextTick();
    });

    afterEach(() => {
      mutateSpy.mockRestore();
    });

    it('calls apollo with the correct variables when the subscribe button is clicked', () => {
      findSubscribeButton().vm.$emit('click');

      expect(mutateSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            id: 'gid://gitlab/WikiPage/1',
            subscribed: true,
          },
        }),
      );
    });

    it('calls apollo with the correct variables when the unsubscribe button is clicked', async () => {
      const id = 'gid://gitlab/WikiPage/1';
      buildWrapper(
        {},
        {
          wikiPage: {
            ...wikiPageQueryMockData,
            id,
            subscribed: true,
          },
        },
      );

      const spy = jest.spyOn(wrapper.vm.$apollo.provider.defaultClient, 'mutate');

      await wrapper.vm.$apollo.queries.wikiPage.refetch();
      await nextTick();

      findSubscribeButton().vm.$emit('click');
      expect(spy).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            id,
            subscribed: false,
          },
        }),
      );
    });

    it('calls the toast method if the mutation succeeds', async () => {
      mutateSpy.mockResolvedValue();
      findSubscribeButton().vm.$emit('click');

      await wrapper.vm.$apollo.queries.wikiPage.refetch();
      await nextTick();

      expect(mockToastShow).toHaveBeenCalled();
    });

    it('calls the toast method and captures error if the mutation fails', async () => {
      const error = new Error('An error occurred');
      mutateSpy.mockRejectedValue(error);
      const sentrySpy = jest.spyOn(Sentry, 'captureException');

      findSubscribeButton().vm.$emit('click');

      await wrapper.vm.$apollo.queries.wikiPage.refetch();
      await nextTick();

      expect(mockToastShow).toHaveBeenCalled();
      expect(sentrySpy).toHaveBeenCalledWith(error);
    });

    it('does not call the apollo mutate method if the state of the subscription has not been resolved', () => {
      expect(mutateSpy).toHaveBeenCalledTimes(0);

      // first click
      findSubscribeButton().vm.$emit('click');
      expect(mutateSpy).toHaveBeenCalledTimes(1);

      // second click, while the subscription state is still resolving
      findSubscribeButton().vm.$emit('click');
      // there should be no second mutation call
      expect(mutateSpy).toHaveBeenCalledTimes(1);
    });
  });
});
