import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import 'vendor/jquery.endless-scroll';
import waitForPromises from 'helpers/wait_for_promises';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import CommitsList from '~/commits';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { sanitize } from '~/lib/dompurify';
import Pager from '~/pager';

jest.mock('~/lib/dompurify', () => ({
  sanitize: jest.fn().mockImplementation((html) => html),
}));

jest.mock('~/lib/graphql', () => {
  return () => ({
    query: jest.fn().mockResolvedValue({
      data: {
        project: { repository: { commit: { descriptionHtml: '&#x000A;<p>Description HTML</p>' } } },
      },
    }),
  });
});

describe('Commits List', () => {
  let commitsList;

  beforeEach(() => {
    setHTMLFixture(`
      <form class="commits-search-form" action="/h5bp/html5-boilerplate/commits/main">
        <input id="commits-search">
      </form>
      <ol id="commits-list">
        <button class="js-toggle-button" data-commit-id="123">Toggle</button>
        <div class="js-toggle-content" data-commit-id="123"></div>
      </ol>
    `);
    jest.spyOn(Pager, 'init').mockImplementation(() => {});
    commitsList = new CommitsList(25);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('should be defined', () => {
    expect(CommitsList).toBeDefined();
  });

  describe('processCommits', () => {
    it('should join commit headers', () => {
      commitsList.$contentList = $(`
        <div>
          <li class="commit-header" data-day="2016-09-20">
            <span class="day">20 Sep, 2016</span>
            <span class="commits-count">1 commit</span>
          </li>
          <li class="commit"></li>
        </div>
      `);

      const data = `
        <li class="commit-header" data-day="2016-09-20">
          <span class="day">20 Sep, 2016</span>
          <span class="commits-count">1 commit</span>
        </li>
        <li class="commit"></li>
      `;

      // The last commit header should be removed
      // since the previous one has the same data-day value.
      expect(commitsList.processCommits(data).find('li.commit-header').length).toBe(0);
    });
  });

  describe('on entering input', () => {
    let ajaxSpy;
    let mock;

    beforeEach(() => {
      commitsList.searchField.val('');

      jest.spyOn(window.history, 'replaceState').mockImplementation(() => {});
      mock = new MockAdapter(axios);

      mock.onGet('/h5bp/html5-boilerplate/commits/main').reply(HTTP_STATUS_OK, {
        html: '<li>Result</li>',
      });

      ajaxSpy = jest.spyOn(axios, 'get');
    });

    afterEach(() => {
      mock.restore();
    });

    it('should save the last search string', async () => {
      commitsList.searchField.val('GitLab');
      await commitsList.filterResults();
      expect(ajaxSpy).toHaveBeenCalled();
      expect(commitsList.lastSearch).toEqual('GitLab');
    });

    it('should not make ajax call if the input does not change', async () => {
      await commitsList.filterResults();
      expect(ajaxSpy).not.toHaveBeenCalled();
      expect(commitsList.lastSearch).toEqual('');
    });
  });

  describe('commit details', () => {
    const findContentToggleButton = () => document.querySelector('.js-toggle-button');
    const findLoadingSpinner = () => document.querySelector('.gl-spinner');
    const findContentElement = () => document.querySelector('.js-toggle-content');
    let jqueryOnSpy;

    beforeEach(() => {
      jqueryOnSpy = jest.spyOn($.fn, 'on');
      commitsList = new CommitsList();
    });

    it('initializes click handler for loading commit details', () => {
      commitsList = new CommitsList();

      expect(jqueryOnSpy).toHaveBeenCalledWith('click', '.js-toggle-button', expect.any(Function));
    });

    describe('when clicking toggle button', () => {
      let contentElement;

      beforeEach(() => {
        contentElement = findContentElement();
      });

      it('fetches and renders commit details', async () => {
        findContentToggleButton().click();

        expect(findLoadingSpinner()).not.toBe(null);

        await waitForPromises();
        expect(contentElement.innerHTML).toBe('<p>Description HTML</p>');
        expect(findLoadingSpinner()).toBe(null);
      });

      it('sanitizes the content', async () => {
        findContentToggleButton().click();

        await waitForPromises();
        expect(sanitize).toHaveBeenCalledWith('<p>Description HTML</p>');
      });

      it('sets content loaded attribute when details are fetched', async () => {
        expect(contentElement.dataset.contentLoaded).toBeUndefined();
        findContentToggleButton().click();

        await waitForPromises();
        expect(contentElement.dataset.contentLoaded).toBe('true');
        expect(findLoadingSpinner()).toBe(null);
      });
    });
  });
});
