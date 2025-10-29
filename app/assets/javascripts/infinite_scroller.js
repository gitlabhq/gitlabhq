import { debounce } from 'lodash';

export class InfiniteScroller {
  static events = {
    htmlInserted: 'htmlInserted',
  };

  eventTarget = new EventTarget();

  #fetchNextPage = null;
  #root = null;
  #limit = null;
  #offset = null;
  #observer = null;
  #controller = null;
  #debouncedIntersectionHandler = null;

  constructor({ fetchNextPage, root, limit, startingOffset = 0 }) {
    this.#fetchNextPage = fetchNextPage;
    this.#root = root;
    this.#limit = limit;
    this.#offset = startingOffset;
    this.#debouncedIntersectionHandler = debounce(this.#handleIntersection.bind(this), 100);
  }

  initialize() {
    this.#observer = new IntersectionObserver(this.#debouncedIntersectionHandler, {
      root: document.querySelector('.js-static-panel-inner'),
    });
    this.#observer.observe(this.#getObservedElement());
  }

  destroy() {
    this.#debouncedIntersectionHandler.cancel();
    if (this.#controller) this.#controller.abort();
    this.#observer.disconnect();
  }

  #setLoadingVisibility(visible) {
    const el = this.#root.querySelector('.js-infinite-scrolling-loading');
    el.style.visibility = visible ? '' : 'hidden';
  }

  #insertPage(html, isEmptyPage) {
    const content = this.#root.querySelector('.js-infinite-scrolling-content');
    // empty page should only be inserted when there's no content
    if (content.innerHTML && isEmptyPage) return;
    // eslint-disable-next-line no-unsanitized/method
    content.insertAdjacentHTML('beforeend', html);
    this.eventTarget.dispatchEvent(new CustomEvent(InfiniteScroller.events.htmlInserted));
  }

  async #loadNextPage() {
    if (this.#controller) this.#controller.abort();
    this.#setLoadingVisibility(true);
    this.#controller = new AbortController();
    const result = await this.#fetchNextPage(this.#offset, this.#controller.signal);
    this.#controller = null;
    if (!result) return false;
    const { html, count } = result;
    this.#insertPage(html, count === 0);
    if (count !== this.#limit) {
      this.#setLoadingVisibility(false);
      this.#observer.disconnect();
      return false;
    }
    this.#offset += count;
    return true;
  }

  #getObservedElement() {
    return this.#root.querySelector('.js-infinite-scrolling-page-end');
  }

  async #handleIntersection([entry]) {
    if (!entry.isIntersecting) return;
    // we need to unobserve and observe again because
    // if the inserted content didn't move the observed element outside the viewport
    // then IntersectionObserver won't be triggered
    // so we trigger this manually
    this.#observer.unobserve(this.#getObservedElement());
    const loadNext = await this.#loadNextPage();
    if (loadNext) this.#observer.observe(this.#getObservedElement());
  }
}
