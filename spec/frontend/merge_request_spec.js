import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import htmlMergeRequestWithTaskList from 'test_fixtures/merge_requests/merge_request_with_task_list.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'spec/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_CONFLICT, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import MergeRequest from '~/merge_request';

jest.mock('~/alert');

describe('MergeRequest', () => {
  const test = {};
  describe('task lists', () => {
    let mock;

    beforeEach(() => {
      setHTMLFixture(htmlMergeRequestWithTaskList);

      jest.spyOn(axios, 'patch');
      mock = new MockAdapter(axios);

      mock
        .onPatch(`${TEST_HOST}/frontend-fixtures/merge-requests-project/-/merge_requests/1.json`)
        .reply(HTTP_STATUS_OK, {});

      test.merge = new MergeRequest();
      return test.merge;
    });

    afterEach(() => {
      mock.restore();
      resetHTMLFixture();
    });

    it('modifies the Markdown field', async () => {
      jest.spyOn($, 'ajax').mockImplementation();
      const changeEvent = document.createEvent('HTMLEvents');
      changeEvent.initEvent('change', true, true);
      $('input[type=checkbox]').first().attr('checked', true)[0].dispatchEvent(changeEvent);

      await waitForPromises();

      expect($('.js-task-list-field').val()).toBe(
        '- [x] Task List Item\n- [ ]\n- [ ] Task List Item 2\n',
      );
    });

    it('ensure that task with only spaces does not get checked incorrectly', async () => {
      // fixed in 'deckar01-task_list', '2.2.1' gem
      jest.spyOn($, 'ajax').mockImplementation();
      const changeEvent = document.createEvent('HTMLEvents');
      changeEvent.initEvent('change', true, true);
      $('input[type=checkbox]').last().attr('checked', true)[0].dispatchEvent(changeEvent);

      await waitForPromises();

      expect($('.js-task-list-field').val()).toBe(
        '- [ ] Task List Item\n- [ ]\n- [x] Task List Item 2\n',
      );
    });

    describe('tasklist', () => {
      const lineNumber = 8;
      const lineSource = '- [ ] item 8';
      const index = 3;
      const checked = true;

      it('submits an ajax request on tasklist:changed', async () => {
        $('.js-task-list-field').trigger({
          type: 'tasklist:changed',
          detail: { lineNumber, lineSource, index, checked },
        });

        await waitForPromises();

        expect(axios.patch).toHaveBeenCalledWith(
          `${TEST_HOST}/frontend-fixtures/merge-requests-project/-/merge_requests/1.json`,
          {
            merge_request: {
              description: '- [ ] Task List Item\n- [ ]\n- [ ] Task List Item 2\n',
              lock_version: 0,
              update_task: { line_number: lineNumber, line_source: lineSource, index, checked },
            },
          },
        );
      });

      it('shows an error notification when tasklist update failed', async () => {
        mock
          .onPatch(`${TEST_HOST}/frontend-fixtures/merge-requests-project/-/merge_requests/1.json`)
          .reply(HTTP_STATUS_CONFLICT, {});

        $('.js-task-list-field').trigger({
          type: 'tasklist:changed',
          detail: { lineNumber, lineSource, index, checked },
        });

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message:
              'Someone edited this merge request at the same time you did. Please refresh the page to see changes.',
          }),
        );
      });
    });
  });
});
