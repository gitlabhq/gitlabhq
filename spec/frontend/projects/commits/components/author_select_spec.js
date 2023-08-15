import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import setWindowLocation from 'helpers/set_window_location_helper';
import AuthorSelect from '~/projects/commits/components/author_select.vue';
import { createStore } from '~/projects/commits/store';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

Vue.use(Vuex);

const commitsPath = 'author/search/url';
const currentAuthor = 'lorem';
const authors = [
  {
    id: 1,
    name: currentAuthor,
    username: 'ipsum',
    avatar_url: 'some/url',
  },
  {
    id: 2,
    name: 'lorem2',
    username: 'ipsum2',
    avatar_url: 'some/url/2',
  },
];

describe('Author Select', () => {
  let store;
  let wrapper;

  const createComponent = () => {
    setHTMLFixture(`
      <div class="js-project-commits-show">
        <input id="commits-search" type="text" />
        <div id="commits-list"></div>
      </div>
    `);

    wrapper = shallowMount(AuthorSelect, {
      store: new Vuex.Store(store),
      propsData: {
        projectCommitsEl: document.querySelector('.js-project-commits-show'),
      },
      stubs: {
        GlCollapsibleListbox,
        GlListboxItem,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    store.actions.fetchAuthors = jest.fn();

    createComponent();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const findListboxContainer = () => wrapper.findComponent({ ref: 'listboxContainer' });
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxItems = () => wrapper.findAllComponents(GlListboxItem);

  describe('user is searching via "filter by commit message"', () => {
    beforeEach(() => {
      setWindowLocation(`?search=foo`);
      createComponent();
    });

    it('does not disable listbox container', () => {
      expect(findListboxContainer().attributes('disabled')).toBeUndefined();
    });

    it('has correct tooltip message', () => {
      expect(findListboxContainer().attributes('title')).toBe(
        'Searching by both author and message is currently not supported.',
      );
    });

    it('disables listbox', () => {
      expect(findListbox().attributes('disabled')).toBeDefined();
    });
  });

  describe('listbox', () => {
    beforeEach(() => {
      store.state.commitsPath = commitsPath;
    });

    it('displays correct default text', () => {
      expect(findListbox().props('toggleText')).toBe('Author');
    });

    it('displays the current selected author', async () => {
      setWindowLocation(`?author=${currentAuthor}`);
      createComponent();

      await nextTick();
      expect(findListbox().props('toggleText')).toBe(currentAuthor);
    });

    it('displays correct header text', () => {
      expect(findListbox().props('headerText')).toBe('Search by author');
    });

    it('does not have popover text by default', () => {
      expect(wrapper.attributes('title')).toBeUndefined();
    });

    it('passes selected author to redirectPath', () => {
      const redirectPath = `${commitsPath}?author=${currentAuthor}`;

      findListbox().vm.$emit('select', currentAuthor);

      expect(visitUrl).toHaveBeenCalledWith(redirectPath);
    });

    it('does not pass any author to redirectPath', () => {
      const redirectPath = commitsPath;

      findListbox().vm.$emit('select', '');

      expect(visitUrl).toHaveBeenCalledWith(redirectPath);
    });
  });

  describe('listbox search box', () => {
    it('has correct placeholder', () => {
      expect(findListbox().props('searchPlaceholder')).toBe('Search');
    });

    it('fetch authors on input change', () => {
      const authorName = 'lorem';
      findListbox().vm.$emit('search', authorName);

      expect(store.actions.fetchAuthors).toHaveBeenCalledWith(expect.anything(), authorName);
    });
  });

  describe('listbox list', () => {
    beforeEach(() => {
      store.state.commitsAuthors = authors;
    });

    it('has a "Any Author" as the first list item', () => {
      expect(findListboxItems().at(0).text()).toBe('Any Author');
    });

    it('displays the project authors', () => {
      expect(findListboxItems()).toHaveLength(authors.length + 1);
    });

    it("display the author's name", () => {
      expect(findListboxItems().at(1).text()).toContain(currentAuthor);
    });
  });
});
