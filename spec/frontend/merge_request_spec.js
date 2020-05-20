import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import MergeRequest from '~/merge_request';
import CloseReopenReportToggle from '~/close_reopen_report_toggle';
import IssuablesHelper from '~/helpers/issuables_helper';
import { TEST_HOST } from 'spec/test_constants';

describe('MergeRequest', () => {
  const test = {};
  describe('task lists', () => {
    let mock;

    preloadFixtures('merge_requests/merge_request_with_task_list.html');
    beforeEach(() => {
      loadFixtures('merge_requests/merge_request_with_task_list.html');

      jest.spyOn(axios, 'patch');
      mock = new MockAdapter(axios);

      mock
        .onPatch(`${TEST_HOST}/frontend-fixtures/merge-requests-project/-/merge_requests/1.json`)
        .reply(200, {});

      test.merge = new MergeRequest();
      return test.merge;
    });

    afterEach(() => {
      mock.restore();
    });

    it('modifies the Markdown field', done => {
      jest.spyOn($, 'ajax').mockImplementation();
      const changeEvent = document.createEvent('HTMLEvents');
      changeEvent.initEvent('change', true, true);
      $('input[type=checkbox]')
        .first()
        .attr('checked', true)[0]
        .dispatchEvent(changeEvent);
      setImmediate(() => {
        expect($('.js-task-list-field').val()).toBe(
          '- [x] Task List Item\n- [ ]   \n- [ ] Task List Item 2\n',
        );
        done();
      });
    });

    it('ensure that task with only spaces does not get checked incorrectly', done => {
      // fixed in 'deckar01-task_list', '2.2.1' gem
      jest.spyOn($, 'ajax').mockImplementation();
      const changeEvent = document.createEvent('HTMLEvents');
      changeEvent.initEvent('change', true, true);
      $('input[type=checkbox]')
        .last()
        .attr('checked', true)[0]
        .dispatchEvent(changeEvent);
      setImmediate(() => {
        expect($('.js-task-list-field').val()).toBe(
          '- [ ] Task List Item\n- [ ]   \n- [x] Task List Item 2\n',
        );
        done();
      });
    });

    describe('tasklist', () => {
      const lineNumber = 8;
      const lineSource = '- [ ] item 8';
      const index = 3;
      const checked = true;

      it('submits an ajax request on tasklist:changed', done => {
        $('.js-task-list-field').trigger({
          type: 'tasklist:changed',
          detail: { lineNumber, lineSource, index, checked },
        });

        setImmediate(() => {
          expect(axios.patch).toHaveBeenCalledWith(
            `${TEST_HOST}/frontend-fixtures/merge-requests-project/-/merge_requests/1.json`,
            {
              merge_request: {
                description: '- [ ] Task List Item\n- [ ]   \n- [ ] Task List Item 2\n',
                lock_version: 0,
                update_task: { line_number: lineNumber, line_source: lineSource, index, checked },
              },
            },
          );

          done();
        });
      });

      it('shows an error notification when tasklist update failed', done => {
        mock
          .onPatch(`${TEST_HOST}/frontend-fixtures/merge-requests-project/-/merge_requests/1.json`)
          .reply(409, {});

        $('.js-task-list-field').trigger({
          type: 'tasklist:changed',
          detail: { lineNumber, lineSource, index, checked },
        });

        setImmediate(() => {
          expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
            'Someone edited this merge request at the same time you did. Please refresh the page to see changes.',
          );

          done();
        });
      });
    });
  });

  describe('class constructor', () => {
    beforeEach(() => {
      jest.spyOn($, 'ajax').mockImplementation();
    });

    it('calls .initCloseReopenReport', () => {
      jest.spyOn(IssuablesHelper, 'initCloseReopenReport').mockImplementation(() => {});

      new MergeRequest(); // eslint-disable-line no-new

      expect(IssuablesHelper.initCloseReopenReport).toHaveBeenCalled();
    });

    it('calls .initDroplab', () => {
      const container = {
        querySelector: jest.fn().mockName('container.querySelector'),
      };
      const dropdownTrigger = {};
      const dropdownList = {};
      const button = {};

      jest.spyOn(CloseReopenReportToggle.prototype, 'initDroplab').mockImplementation(() => {});
      jest.spyOn(document, 'querySelector').mockReturnValue(container);

      container.querySelector
        .mockReturnValueOnce(dropdownTrigger)
        .mockReturnValueOnce(dropdownList)
        .mockReturnValueOnce(button);

      new MergeRequest(); // eslint-disable-line no-new

      expect(document.querySelector).toHaveBeenCalledWith('.js-issuable-close-dropdown');
      expect(container.querySelector).toHaveBeenCalledWith('.js-issuable-close-toggle');
      expect(container.querySelector).toHaveBeenCalledWith('.js-issuable-close-menu');
      expect(container.querySelector).toHaveBeenCalledWith('.js-issuable-close-button');
      expect(CloseReopenReportToggle.prototype.initDroplab).toHaveBeenCalled();
    });
  });

  describe('hideCloseButton', () => {
    describe('merge request of another user', () => {
      beforeEach(() => {
        loadFixtures('merge_requests/merge_request_with_task_list.html');
        test.el = document.querySelector('.js-issuable-actions');
        new MergeRequest(); // eslint-disable-line no-new
        MergeRequest.hideCloseButton();
      });

      it('hides the dropdown close item and selects the next item', () => {
        const closeItem = test.el.querySelector('li.close-item');
        const smallCloseItem = test.el.querySelector('.js-close-item');
        const reportItem = test.el.querySelector('li.report-item');

        expect(closeItem).toHaveClass('hidden');
        expect(smallCloseItem).toHaveClass('hidden');
        expect(reportItem).toHaveClass('droplab-item-selected');
        expect(reportItem).not.toHaveClass('hidden');
      });
    });

    describe('merge request of current_user', () => {
      beforeEach(() => {
        loadFixtures('merge_requests/merge_request_of_current_user.html');
        test.el = document.querySelector('.js-issuable-actions');
        MergeRequest.hideCloseButton();
      });

      it('hides the close button', () => {
        const closeButton = test.el.querySelector('.btn-close');
        const smallCloseItem = test.el.querySelector('.js-close-item');

        expect(closeButton).toHaveClass('hidden');
        expect(smallCloseItem).toHaveClass('hidden');
      });
    });
  });
});
