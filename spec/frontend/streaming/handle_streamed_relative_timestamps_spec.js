import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import { handleStreamedRelativeTimestamps } from '~/streaming/handle_streamed_relative_timestamps';
import { localTimeAgo } from '~/lib/utils/datetime_utility';
import { useMockIntersectionObserver } from 'helpers/mock_dom_observer';

jest.mock('~/lib/utils/datetime_utility');

const TIMESTAMP_MOCK = `<div class="js-timeago">Oct 2, 2019</div>`;

describe('handleStreamedRelativeTimestamps', () => {
  const findRoot = () => document.querySelector('#root');
  const findStreamingElement = () => document.querySelector('streaming-element');
  const findTimestamp = () => document.querySelector('.js-timeago');

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when element is present', () => {
    beforeEach(() => {
      setHTMLFixture(`<div id="root">${TIMESTAMP_MOCK}</div>`);
      handleStreamedRelativeTimestamps(findRoot());
    });

    it('does nothing', async () => {
      await waitForPromises();
      expect(localTimeAgo).not.toHaveBeenCalled();
    });
  });

  describe('when element is streamed', () => {
    let relativeTimestampsHandler;
    const { trigger: triggerIntersection } = useMockIntersectionObserver();

    const insertStreamingElement = () =>
      findRoot().insertAdjacentHTML('afterbegin', `<streaming-element></streaming-element>`);

    beforeEach(() => {
      setHTMLFixture('<div id="root"></div>');
      relativeTimestampsHandler = handleStreamedRelativeTimestamps(findRoot());
    });

    it('formats and unobserved the timestamp when inserted and intersecting', async () => {
      insertStreamingElement();
      await waitForPromises();
      findStreamingElement().insertAdjacentHTML('afterbegin', TIMESTAMP_MOCK);
      await waitForPromises();

      const timestamp = findTimestamp();
      const unobserveMock = jest.fn();

      triggerIntersection(findTimestamp(), {
        entry: { isIntersecting: true },
        observer: { unobserve: unobserveMock },
      });

      expect(unobserveMock).toHaveBeenCalled();
      expect(localTimeAgo).toHaveBeenCalledWith([timestamp]);
    });

    it('does not format the timestamp when inserted but not intersecting', async () => {
      insertStreamingElement();
      await waitForPromises();
      findStreamingElement().insertAdjacentHTML('afterbegin', TIMESTAMP_MOCK);
      await waitForPromises();

      const unobserveMock = jest.fn();

      triggerIntersection(findTimestamp(), {
        entry: { isIntersecting: false },
        observer: { unobserve: unobserveMock },
      });

      expect(unobserveMock).not.toHaveBeenCalled();
      expect(localTimeAgo).not.toHaveBeenCalled();
    });

    it('does not format the time when destroyed', async () => {
      insertStreamingElement();

      const stop = await relativeTimestampsHandler;
      stop();

      await waitForPromises();
      findStreamingElement().insertAdjacentHTML('afterbegin', TIMESTAMP_MOCK);
      await waitForPromises();

      triggerIntersection(findTimestamp(), { entry: { isIntersecting: true } });

      expect(localTimeAgo).not.toHaveBeenCalled();
    });
  });
});
