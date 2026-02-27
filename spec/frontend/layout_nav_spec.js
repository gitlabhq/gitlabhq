import { initScrollingTabs } from '~/layout_nav';
import { setHTMLFixture } from './__helpers__/fixtures';

describe('initScrollingTabs', () => {
  const originalResizeObserver = global.ResizeObserver;
  const htmlFixture = `
    <div>
      <button type='button' class='fade-left'></button>
      <button type='button' class='fade-right'></button>
      <div class='scrolling-tabs'></div>
    </div>
    <div>
      <button type='button' class='fade-left'></button>
      <button type='button' class='fade-right'></button>
      <div class='scrolling-tabs'></div>
    </div>
  `;
  const findTabs = () => document.querySelector('.scrolling-tabs');
  const findAllTabs = () => document.querySelectorAll('.scrolling-tabs');
  const findScrollLeftButton = () => document.querySelector('button.fade-left');
  const findScrollRightButton = () => document.querySelector('button.fade-right');

  beforeEach(() => {
    setHTMLFixture(htmlFixture);
  });

  afterEach(() => {
    global.ResizeObserver = originalResizeObserver;
  });

  it('scrolls left when clicking on the left button', () => {
    initScrollingTabs();
    const tabs = findTabs();
    tabs.scrollBy = jest.fn();
    const fadeLeft = findScrollLeftButton();

    fadeLeft.click();

    expect(tabs.scrollBy).toHaveBeenCalledWith({ left: -200, behavior: 'smooth' });
  });

  it('scrolls right when clicking on the right button', () => {
    initScrollingTabs();
    const tabs = findTabs();
    tabs.scrollBy = jest.fn();
    const fadeRight = findScrollRightButton();

    fadeRight.click();

    expect(tabs.scrollBy).toHaveBeenCalledWith({ left: 200, behavior: 'smooth' });
  });

  it('uses ResizeObserver to watch for size changes', () => {
    const observeMock = jest.fn();
    global.ResizeObserver = jest.fn().mockImplementation(() => ({
      observe: observeMock,
      unobserve: jest.fn(),
      disconnect: jest.fn(),
    }));

    initScrollingTabs();

    const tabs = findAllTabs();
    expect(global.ResizeObserver).toHaveBeenCalledTimes(1);
    expect(observeMock).toHaveBeenCalledTimes(tabs.length);
    tabs.forEach((tab) => {
      expect(observeMock).toHaveBeenCalledWith(tab);
    });
  });
});
