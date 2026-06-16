import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import setWindowLocation from 'helpers/set_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AuthorSelect from '~/projects/commits/components/author_select.vue';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));
jest.mock('~/alert');

const path = '/-/autocomplete/users.json';
const commitsPath = 'author/search/url';
const projectId = '8';
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
  let axiosMock;
  let wrapper;

  beforeAll(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.reset();
  });

  afterAll(() => {
    axiosMock.restore();
  });

  const createComponent = () => {
    setHTMLFixture(`
      <div class="js-project-commits-show">
        <input id="commits-search" type="text" />
        <div id="commits-list"></div>
      </div>
    `);

    wrapper = shallowMount(AuthorSelect, {
      propsData: {
        projectCommitsEl: document.querySelector('.js-project-commits-show'),
      },
      provide: {
        commitsPath,
        projectId,
      },
      stubs: {
        GlCollapsibleListbox,
        GlListboxItem,
      },
    });
  };

  beforeEach(() => {
    axiosMock.onGet(path).reply(HTTP_STATUS_OK, []);
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

    describe('date filter forwarding', () => {
      it('preserves committed_after param when selecting an author', () => {
        setWindowLocation('?committed_after=2025-01-01');

        findListbox().vm.$emit('select', currentAuthor);

        expect(visitUrl).toHaveBeenCalledWith(
          `${commitsPath}?committed_after=2025-01-01&author=${currentAuthor}`,
        );
      });

      it('preserves committed_before param when selecting an author', () => {
        setWindowLocation('?committed_before=2025-12-31');

        findListbox().vm.$emit('select', currentAuthor);

        expect(visitUrl).toHaveBeenCalledWith(
          `${commitsPath}?committed_before=2025-12-31&author=${currentAuthor}`,
        );
      });

      it('preserves both date params when clearing the author selection', () => {
        setWindowLocation('?committed_after=2025-01-01&committed_before=2025-12-31');

        findListbox().vm.$emit('select', '');

        expect(visitUrl).toHaveBeenCalledWith(
          `${commitsPath}?committed_after=2025-01-01&committed_before=2025-12-31`,
        );
      });
    });
  });

  describe('listbox search box', () => {
    it('has correct placeholder', () => {
      expect(findListbox().props('searchPlaceholder')).toBe('Search');
    });

    it('fetch authors on input change', async () => {
      await waitForPromises();
      axiosMock.resetHistory();
      jest.useFakeTimers();

      findListbox().vm.$emit('search', 'lorem');
      jest.runAllTimers();
      jest.useRealTimers();
      await waitForPromises();

      expect(axiosMock.history.get).toContainEqual(
        expect.objectContaining({
          params: expect.objectContaining({ search: 'lorem' }),
        }),
      );
    });
  });

  describe('fetchAuthors', () => {
    it('populates the listbox with authors on success', async () => {
      axiosMock.reset();
      axiosMock.onGet(path).reply(HTTP_STATUS_OK, authors);
      createComponent();

      await waitForPromises();

      expect(findListboxItems()).toHaveLength(authors.length + 1);
      expect(findListboxItems().at(0).text()).toBe('Any Author');
      expect(findListboxItems().at(1).text()).toContain(currentAuthor);
    });

    it('creates an alert on error', async () => {
      axiosMock.reset();
      axiosMock.onGet(path).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      createComponent();

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred fetching the project authors.',
      });
    });
  });
});
