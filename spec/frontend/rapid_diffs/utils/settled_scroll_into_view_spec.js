import { settledScrollIntoView } from '~/rapid_diffs/utils/settled_scroll_into_view';

describe('settledScrollIntoView', () => {
  let element;
  let root;

  beforeEach(() => {
    root = document.createElement('div');
    root.dataset.rapidDiffs = '';
    element = document.createElement('div');
    root.appendChild(element);
    document.body.appendChild(root);
    element.scrollIntoView = jest.fn();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('calls scrollIntoView immediately', () => {
    settledScrollIntoView(element, root);
    expect(element.scrollIntoView).toHaveBeenCalledWith({ block: 'start' });
  });

  it('passes custom options to scrollIntoView', () => {
    settledScrollIntoView(element, root, { block: 'center' });
    expect(element.scrollIntoView).toHaveBeenCalledWith({ block: 'center' });
  });

  it('re-scrolls on contentvisibilityautostatechange', () => {
    settledScrollIntoView(element, root);
    element.scrollIntoView.mockClear();
    root.dispatchEvent(new Event('contentvisibilityautostatechange', { bubbles: true }));
    expect(element.scrollIntoView).toHaveBeenCalledTimes(1);
  });

  it('returns a promise that resolves after settle timeout', async () => {
    const promise = settledScrollIntoView(element, root);
    expect(promise).toBeInstanceOf(Promise);
    element.scrollIntoView.mockClear();
    jest.runOnlyPendingTimers();
    await promise;
    expect(element.scrollIntoView).toHaveBeenCalledTimes(1);
  });

  it('aborts on user scroll', () => {
    settledScrollIntoView(element, root);
    window.dispatchEvent(new Event('scroll'));
    element.scrollIntoView.mockClear();
    window.dispatchEvent(new Event('scroll'));
    root.dispatchEvent(new Event('contentvisibilityautostatechange', { bubbles: true }));
    expect(element.scrollIntoView).not.toHaveBeenCalled();
  });

  it('aborts previous call when called again', () => {
    const element2 = document.createElement('div');
    root.appendChild(element2);
    element2.scrollIntoView = jest.fn();
    settledScrollIntoView(element, root);
    settledScrollIntoView(element2, root);
    element.scrollIntoView.mockClear();
    root.dispatchEvent(new Event('contentvisibilityautostatechange', { bubbles: true }));
    expect(element.scrollIntoView).not.toHaveBeenCalled();
    expect(element2.scrollIntoView).toHaveBeenCalled();
  });
});
