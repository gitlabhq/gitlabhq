import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import 'vendor/jquery.endless-scroll';
import CommitsList from '~/commits';
import axios from '~/lib/utils/axios_utils';
import Pager from '~/pager';

describe('Commits List', () => {
  let commitsList;

  beforeEach(() => {
    setFixtures(`
      <form class="commits-search-form" action="/h5bp/html5-boilerplate/commits/main">
        <input id="commits-search">
      </form>
      <ol id="commits-list"></ol>
      `);
    jest.spyOn(Pager, 'init').mockImplementation(() => {});
    commitsList = new CommitsList(25);
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

      mock.onGet('/h5bp/html5-boilerplate/commits/main').reply(200, {
        html: '<li>Result</li>',
      });

      ajaxSpy = jest.spyOn(axios, 'get');
    });

    afterEach(() => {
      mock.restore();
    });

    it('should save the last search string', (done) => {
      commitsList.searchField.val('GitLab');
      commitsList
        .filterResults()
        .then(() => {
          expect(ajaxSpy).toHaveBeenCalled();
          expect(commitsList.lastSearch).toEqual('GitLab');

          done();
        })
        .catch(done.fail);
    });

    it('should not make ajax call if the input does not change', (done) => {
      commitsList
        .filterResults()
        .then(() => {
          expect(ajaxSpy).not.toHaveBeenCalled();
          expect(commitsList.lastSearch).toEqual('');

          done();
        })
        .catch(done.fail);
    });
  });
});
