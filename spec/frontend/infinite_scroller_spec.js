import { useMockIntersectionObserver } from 'helpers/mock_dom_observer';
import { InfiniteScroller } from '~/infinite_scroller';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';

describe('Infinite scroller', () => {
  let fetchNextPage;
  let resolveNextPage;
  let resolveLastPage;
  let limit;
  let scroller;
  let startingOffset;
  let signal;
  const { trigger: triggerIntersection } = useMockIntersectionObserver();

  const getRoot = () => document.querySelector('.js-infinite-scrolling-root');
  const getContent = () => document.querySelector('.js-infinite-scrolling-content');
  const getPageEnd = () => document.querySelector('.js-infinite-scrolling-page-end');
  const getLoading = () => document.querySelector('.js-infinite-scrolling-loading');

  const createScroller = () => {
    scroller = new InfiniteScroller({
      fetchNextPage,
      root: getRoot(),
      limit,
      startingOffset,
    });
    scroller.initialize();
  };

  const triggerNextPage = () => {
    triggerIntersection(getPageEnd(), { entry: { isIntersecting: true } });
  };

  beforeEach(() => {
    startingOffset = undefined;
    limit = 20;
    fetchNextPage = jest.fn((offset, abortSignal) => {
      signal = abortSignal;
      return new Promise((resolve) => {
        resolveNextPage = (nextPage = { count: limit, html: `<div>content</div>` }) =>
          resolve(nextPage);
        resolveLastPage = (nextPage = { count: 0, html: `<div>empty</div>` }) => resolve(nextPage);
      });
    });
    setHTMLFixture(`
      <div class="js-infinite-scrolling-root">
        <div class="js-infinite-scrolling-content"></div>
        <div class="js-infinite-scrolling-page-end">
          <div class="js-infinite-scrolling-loading"></div>
        </div>
      </div>
    `);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('loads initial page', async () => {
    createScroller();
    triggerNextPage();
    await resolveNextPage();
    expect(getContent().textContent).toBe('content');
    expect(fetchNextPage).toHaveBeenCalledWith(0, expect.any(AbortSignal));
    resolveLastPage();
  });

  it('loads initial page with starting offset', async () => {
    startingOffset = 20;
    createScroller({ startingOffset });
    triggerNextPage();
    await resolveNextPage();
    expect(getContent().textContent).toBe('content');
    expect(fetchNextPage).toHaveBeenCalledWith(startingOffset, expect.any(AbortSignal));
    resolveLastPage();
  });

  it('loads page after page', async () => {
    createScroller();
    triggerNextPage();
    await resolveNextPage();
    triggerNextPage();
    await resolveNextPage();
    triggerNextPage();
    await resolveNextPage();
    expect(getContent().textContent).toBe('contentcontentcontent');
    expect(fetchNextPage).toHaveBeenNthCalledWith(1, 0, expect.any(AbortSignal));
    expect(fetchNextPage).toHaveBeenNthCalledWith(2, limit, expect.any(AbortSignal));
    expect(fetchNextPage).toHaveBeenNthCalledWith(3, limit * 2, expect.any(AbortSignal));
    resolveLastPage();
  });

  it('cancels previous request on repeated intersection', () => {
    createScroller();
    const abort = jest.fn();
    triggerNextPage();
    signal.addEventListener('abort', abort);
    triggerNextPage();
    expect(abort).toHaveBeenCalled();
    resolveLastPage();
  });

  it('does not cancel finalized request on repeated intersection', async () => {
    createScroller();
    const abort = jest.fn();
    triggerNextPage();
    await resolveNextPage();
    signal.addEventListener('abort', abort);
    triggerNextPage();
    expect(abort).not.toHaveBeenCalled();
    resolveLastPage();
  });

  it('stops loading on partial page', async () => {
    createScroller();
    triggerNextPage();
    await resolveNextPage();
    triggerNextPage();
    await resolveNextPage({ count: limit / 2, html: `<div>content</div>` });
    triggerNextPage();
    await resolveNextPage();
    expect(getContent().textContent).toBe('contentcontent');
  });

  it('stops loading on empty page', async () => {
    createScroller();
    triggerNextPage();
    await resolveNextPage();
    triggerNextPage();
    await resolveLastPage();
    triggerNextPage();
    await resolveNextPage();
    expect(getContent().textContent).toBe('content');
  });

  it('shows empty message when content is empty', async () => {
    createScroller();
    triggerNextPage();
    await resolveLastPage();
    expect(getContent().textContent).toBe('empty');
  });

  it('shows loading element when loading starts', () => {
    createScroller();
    triggerNextPage();
    expect(getLoading().style.visibility).toBe('');
    resolveLastPage();
  });

  it('hides loading element when loading ends', async () => {
    createScroller();
    triggerNextPage();
    await resolveLastPage();
    expect(getLoading().style.visibility).toBe('hidden');
  });

  it('emits htmlInserted event', async () => {
    createScroller();
    const callback = jest.fn();
    scroller.eventTarget.addEventListener('htmlInserted', callback);
    triggerNextPage();
    await resolveNextPage();
    expect(callback).toHaveBeenCalled();
    resolveLastPage();
  });

  it('can be destroyed', async () => {
    createScroller();
    triggerNextPage();
    await resolveNextPage();
    scroller.destroy();
    triggerNextPage();
    await resolveNextPage();
    expect(getContent().textContent).toBe('content');
  });

  it('cancels the request on destroy', () => {
    createScroller();
    const abort = jest.fn();
    triggerNextPage();
    signal.addEventListener('abort', abort);
    scroller.destroy();
    expect(abort).toHaveBeenCalled();
  });
});
