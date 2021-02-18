import { GlDropdown, GlDropdownSectionHeader, GlSearchBoxByType, GlDropdownItem } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import * as urlUtility from '~/lib/utils/url_utility';
import AuthorSelect from '~/projects/commits/components/author_select.vue';
import { createStore } from '~/projects/commits/store';

const localVue = createLocalVue();
localVue.use(Vuex);

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
    setFixtures(`
      <div class="js-project-commits-show">
        <input id="commits-search" type="text" />
        <div id="commits-list"></div>
      </div>
    `);

    wrapper = shallowMount(AuthorSelect, {
      localVue,
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
    wrapper.destroy();
  });

  const findDropdownContainer = () => wrapper.find({ ref: 'dropdownContainer' });
  const findDropdown = () => wrapper.find(GlDropdown);
  const findDropdownHeader = () => wrapper.find(GlDropdownSectionHeader);
  const findSearchBox = () => wrapper.find(GlSearchBoxByType);
  const findDropdownItems = () => wrapper.findAll(GlDropdownItem);

  describe('user is searching via "filter by commit message"', () => {
    it('disables dropdown container', () => {
      wrapper.setData({ hasSearchParam: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(findDropdownContainer().attributes('disabled')).toBeFalsy();
      });
    });

    it('has correct tooltip message', () => {
      wrapper.setData({ hasSearchParam: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(findDropdownContainer().attributes('title')).toBe(
          'Searching by both author and message is currently not supported.',
        );
      });
    });

    it('disables dropdown', () => {
      wrapper.setData({ hasSearchParam: false });

      return wrapper.vm.$nextTick().then(() => {
        expect(findDropdown().attributes('disabled')).toBeFalsy();
      });
    });

    it('hasSearchParam if user types a truthy string', () => {
      wrapper.vm.setSearchParam('false');

      expect(wrapper.vm.hasSearchParam).toBeTruthy();
    });
  });

  describe('dropdown', () => {
    it('displays correct default text', () => {
      expect(findDropdown().attributes('text')).toBe('Author');
    });

    it('displays the current selected author', () => {
      wrapper.setData({ currentAuthor });

      return wrapper.vm.$nextTick().then(() => {
        expect(findDropdown().attributes('text')).toBe(currentAuthor);
      });
    });

    it('displays correct header text', () => {
      expect(findDropdownHeader().text()).toBe('Search by author');
    });

    it('does not have popover text by default', () => {
      expect(wrapper.attributes('title')).not.toExist();
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
      return wrapper.vm.$nextTick().then(() => {
        expect(findDropdownItems()).toHaveLength(authors.length + 1);
      });
    });

    it('has the correct props', () => {
      const [{ avatar_url, username }] = authors;
      const result = {
        avatarUrl: avatar_url,
        secondaryText: username,
        isChecked: true,
      };

      wrapper.setData({ currentAuthor });

      return wrapper.vm.$nextTick().then(() => {
        expect(findDropdownItems().at(1).props()).toEqual(expect.objectContaining(result));
      });
    });

    it("display the author's name", () => {
      return wrapper.vm.$nextTick().then(() => {
        expect(findDropdownItems().at(1).text()).toBe(currentAuthor);
      });
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
