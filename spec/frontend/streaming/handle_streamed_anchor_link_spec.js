import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import { handleStreamedAnchorLink } from '~/streaming/handle_streamed_anchor_link';
import { scrollToElement } from '~/lib/utils/common_utils';
import LineHighlighter from '~/blob/line_highlighter';
import { TEST_HOST } from 'spec/test_constants';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/blob/line_highlighter');

describe('handleStreamedAnchorLink', () => {
  const ANCHOR_START = 'L100';
  const ANCHOR_END = '300';
  const findRoot = () => document.querySelector('#root');

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when single line anchor is given', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL(`${TEST_HOST}#${ANCHOR_START}`);
    });

    describe('when element is present', () => {
      beforeEach(() => {
        setHTMLFixture(`<div id="root"><div id="${ANCHOR_START}"></div></div>`);
        handleStreamedAnchorLink(findRoot());
      });

      it('does nothing', async () => {
        await waitForPromises();
        expect(scrollToElement).not.toHaveBeenCalled();
      });
    });

    describe('when element is streamed', () => {
      let stop;
      const insertElement = () => {
        findRoot().insertAdjacentHTML('afterbegin', `<div id="${ANCHOR_START}"></div>`);
      };

      beforeEach(() => {
        setHTMLFixture('<div id="root"></div>');
        stop = handleStreamedAnchorLink(findRoot());
      });

      afterEach(() => {
        stop = undefined;
      });

      it('scrolls to the anchor when inserted', async () => {
        insertElement();
        await waitForPromises();
        expect(scrollToElement).toHaveBeenCalledTimes(1);
        expect(LineHighlighter).toHaveBeenCalledTimes(1);
      });

      it("doesn't scroll to the anchor when destroyed", async () => {
        stop();
        insertElement();
        await waitForPromises();
        expect(scrollToElement).not.toHaveBeenCalled();
      });
    });
  });

  describe('when line range anchor is given', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL(`${TEST_HOST}#${ANCHOR_START}-${ANCHOR_END}`);
    });

    describe('when last element is present', () => {
      beforeEach(() => {
        setHTMLFixture(`<div id="root"><div id="L${ANCHOR_END}"></div></div>`);
        handleStreamedAnchorLink(findRoot());
      });

      it('does nothing', async () => {
        await waitForPromises();
        expect(scrollToElement).not.toHaveBeenCalled();
      });
    });

    describe('when last element is streamed', () => {
      let stop;
      const insertElement = () => {
        findRoot().insertAdjacentHTML(
          'afterbegin',
          `<div id="${ANCHOR_START}"></div><div id="L${ANCHOR_END}"></div>`,
        );
      };

      beforeEach(() => {
        setHTMLFixture('<div id="root"></div>');
        stop = handleStreamedAnchorLink(findRoot());
      });

      afterEach(() => {
        stop = undefined;
      });

      it('scrolls to the anchor when inserted', async () => {
        insertElement();
        await waitForPromises();
        expect(scrollToElement).toHaveBeenCalledTimes(1);
        expect(LineHighlighter).toHaveBeenCalledTimes(1);
      });

      it("doesn't scroll to the anchor when destroyed", async () => {
        stop();
        insertElement();
        await waitForPromises();
        expect(scrollToElement).not.toHaveBeenCalled();
      });
    });
  });

  describe('when anchor is not given', () => {
    beforeEach(() => {
      setHTMLFixture(`<div id="root"></div>`);
      handleStreamedAnchorLink(findRoot());
    });

    it('does nothing', async () => {
      await waitForPromises();
      expect(scrollToElement).not.toHaveBeenCalled();
    });
  });
});
