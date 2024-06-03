import { GlSprintf } from '@gitlab/ui';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiHeader from '~/pages/shared/wikis/components/wiki_header.vue';

describe('pages/shared/wikis/components/wiki_header', () => {
  let wrapper;

  function buildWrapper(provide = {}) {
    wrapper = shallowMountExtended(WikiHeader, {
      provide: {
        pageTitle: 'Wiki page heading',
        isPageTemplate: false,
        showEditButton: true,
        editButtonUrl: 'http://edit.url',
        lastVersion: '2024-06-03T01:53:28.000Z',
        pageVersion: {
          commit: {
            author_name: 'Test author',
            authored_date: '2024-06-03T01:53:28.000Z',
          },
        },
        authorUrl: 'http://author.url',
        ...provide,
      },
      stubs: {
        GlSprintf,
        TimeAgo,
      },
    });
  }

  const findPageHeading = () => wrapper.findByTestId('wiki-page-title');
  const findEditButton = () => wrapper.findByTestId('wiki-edit-button');
  const findLastVersion = () => wrapper.findByTestId('wiki-page-last-version');

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
      expect(findLastVersion().text()).toBe('Last edited by Test author in 3 years');

      buildWrapper({ lastVersion: false });

      expect(findLastVersion().exists()).toBe(false);
    });
  });
});
