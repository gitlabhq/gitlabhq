import { GlDropdown, GlDropdownSectionHeader, GlSearchBoxByType, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as urlUtility from '~/lib/utils/url_utility';
import AuthorSelect from '~/projects/commits/components/author_select.vue';
import { createStore } from '~/projects/commits/store';

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

  const findDropdownContainer = () => wrapper.findComponent({ ref: 'dropdownContainer' });
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownHeader = () => wrapper.findComponent(GlDropdownSectionHeader);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);

  describe('user is searching via "filter by commit message"', () => {
    beforeEach(() => {
      setWindowLocation(`?search=foo`);
      createComponent();
    });

    it('does not disable dropdown container', () => {
      expect(findDropdownContainer().attributes('disabled')).toBeUndefined();
    });

    it('has correct tooltip message', () => {
      expect(findDropdownContainer().attributes('title')).toBe(
        'Searching by both author and message is currently not supported.',
      );
    });

    it('disables dropdown', () => {
      expect(findDropdown().attributes('disabled')).toBeDefined();
    });
  });

  describe('dropdown', () => {
    it('displays correct default text', () => {
      expect(findDropdown().attributes('text')).toBe('Author');
    });

    it('displays the current selected author', async () => {
      setWindowLocation(`?author=${currentAuthor}`);
      createComponent();

      await nextTick();
      expect(findDropdown().attributes('text')).toBe(currentAuthor);
    });

    it('displays correct header text', () => {
      expect(findDropdownHeader().text()).toBe('Search by author');
    });

    it('does not have popover text by default', () => {
      expect(wrapper.attributes('title')).toBeUndefined();
    });
  });

  describe('dropdown search box', () => {
    it('has correct placeholder', () => {
      expect(findSearchBox().attributes('placeholder')).toBe('Search');
    });

    it('fetch authors on input change', () => {
      const authorName = 'lorem';
      findSearchBox().vm.$emit('input', authorName);

      expect(store.actions.fetchAuthors).toHaveBeenCalledWith(expect.anything(), authorName);
    });
  });

  describe('dropdown list', () => {
    beforeEach(() => {
      store.state.commitsAuthors = authors;
      store.state.commitsPath = commitsPath;
    });

    it('has a "Any Author" as the first list item', () => {
      expect(findDropdownItems().at(0).text()).toBe('Any Author');
    });

    it('displays the project authors', () => {
      expect(findDropdownItems()).toHaveLength(authors.length + 1);
    });

    it('has the correct props', async () => {
      setWindowLocation(`?author=${currentAuthor}`);
      createComponent();

      const [{ avatar_url: avatarUrl, username }] = authors;
      const result = {
        avatarUrl,
        secondaryText: username,
        isChecked: true,
      };

      await nextTick();
      expect(findDropdownItems().at(1).props()).toEqual(expect.objectContaining(result));
    });

    it("display the author's name", () => {
      expect(findDropdownItems().at(1).text()).toBe(currentAuthor);
    });

    it('passes selected author to redirectPath', () => {
      const redirectToUrl = `${commitsPath}?author=${currentAuthor}`;
      const spy = jest.spyOn(urlUtility, 'redirectTo');
      spy.mockImplementation(() => 'mock');

      findDropdownItems().at(1).vm.$emit('click');

      expect(spy).toHaveBeenCalledWith(redirectToUrl);
    });

    it('does not pass any author to redirectPath', () => {
      const redirectToUrl = commitsPath;
      const spy = jest.spyOn(urlUtility, 'redirectTo');
      spy.mockImplementation();

      findDropdownItems().at(0).vm.$emit('click');
      expect(spy).toHaveBeenCalledWith(redirectToUrl);
    });
  });
});
