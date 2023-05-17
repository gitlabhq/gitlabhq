import { initScrollingTabs } from '~/layout_nav';
import { setHTMLFixture } from './__helpers__/fixtures';

describe('initScrollingTabs', () => {
  const htmlFixture = `
    <button type='button' class='fade-left'></button>
    <button type='button' class='fade-right'></button>
    <div class='scrolling-tabs'></div>
  `;
  const findTabs = () => document.querySelector('.scrolling-tabs');
  const findScrollLeftButton = () => document.querySelector('button.fade-left');
  const findScrollRightButton = () => document.querySelector('button.fade-right');

  beforeEach(() => {
    setHTMLFixture(htmlFixture);
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
});
