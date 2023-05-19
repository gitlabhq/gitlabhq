import htmlTabs from 'test_fixtures/tabs/tabs.html';
import { GlTabsBehavior, TAB_SHOWN_EVENT, HISTORY_TYPE_HASH } from '~/tabs';
import { ACTIVE_PANEL_CLASS, ACTIVE_TAB_CLASSES } from '~/tabs/constants';
import { getLocationHash } from '~/lib/utils/url_utility';
import { NO_SCROLL_TO_HASH_CLASS } from '~/lib/utils/common_utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import setWindowLocation from 'helpers/set_window_location_helper';

global.CSS = {
  escape: (val) => val,
};

describe('GlTabsBehavior', () => {
  let glTabs;
  let tabShownEventSpy;

  const findByTestId = (testId) => document.querySelector(`[data-testid="${testId}"]`);
  const findTab = (name) => findByTestId(`${name}-tab`);
  const findPanel = (name) => findByTestId(`${name}-panel`);

  const getAttributes = (element) =>
    Array.from(element.attributes).reduce((acc, attr) => {
      acc[attr.name] = attr.value;
      return acc;
    }, {});

  const expectActiveTabAndPanel = (name) => {
    const tab = findTab(name);
    const panel = findPanel(name);

    expect(glTabs.activeTab).toBe(tab);

    expect(getAttributes(tab)).toMatchObject({
      'aria-controls': panel.id,
      'aria-selected': 'true',
      role: 'tab',
      id: expect.any(String),
    });

    ACTIVE_TAB_CLASSES.forEach((klass) => {
      expect(tab.classList.contains(klass)).toBe(true);
    });

    expect(getAttributes(panel)).toMatchObject({
      'aria-labelledby': tab.id,
      role: 'tabpanel',
    });

    expect(panel.classList.contains(ACTIVE_PANEL_CLASS)).toBe(true);
    expect(panel.classList.contains(NO_SCROLL_TO_HASH_CLASS)).toBe(true);
  };

  const expectInactiveTabAndPanel = (name) => {
    const tab = findTab(name);
    const panel = findPanel(name);

    expect(glTabs.activeTab).not.toBe(tab);

    expect(getAttributes(tab)).toMatchObject({
      'aria-controls': panel.id,
      'aria-selected': 'false',
      role: 'tab',
      tabindex: '-1',
      id: expect.any(String),
    });

    ACTIVE_TAB_CLASSES.forEach((klass) => {
      expect(tab.classList.contains(klass)).toBe(false);
    });

    expect(getAttributes(panel)).toMatchObject({
      'aria-labelledby': tab.id,
      role: 'tabpanel',
    });

    expect(panel.classList.contains(ACTIVE_PANEL_CLASS)).toBe(false);
    expect(panel.classList.contains(NO_SCROLL_TO_HASH_CLASS)).toBe(true);
  };

  const expectGlTabShownEvent = (name) => {
    expect(tabShownEventSpy).toHaveBeenCalledTimes(1);

    const [event] = tabShownEventSpy.mock.calls[0];
    expect(event.target).toBe(findTab(name));

    expect(event.detail).toEqual({
      activeTabPanel: findPanel(name),
    });
  };

  const triggerKeyDown = (code, element) => {
    const event = new KeyboardEvent('keydown', { code });

    element.dispatchEvent(event);
  };

  it('throws when instantiated without an element', () => {
    expect(() => new GlTabsBehavior()).toThrow('Cannot instantiate');
  });

  describe('when given an element', () => {
    afterEach(() => {
      glTabs.destroy();

      resetHTMLFixture();
    });

    beforeEach(() => {
      setHTMLFixture(htmlTabs);

      const tabsEl = findByTestId('tabs');
      tabShownEventSpy = jest.fn();
      tabsEl.addEventListener(TAB_SHOWN_EVENT, tabShownEventSpy);

      glTabs = new GlTabsBehavior(tabsEl);
    });

    it('instantiates', () => {
      expect(glTabs).toEqual(expect.any(GlTabsBehavior));
    });

    it('sets the active tab', () => {
      expectActiveTabAndPanel('foo');
    });

    it(`does not fire an initial ${TAB_SHOWN_EVENT} event`, () => {
      expect(tabShownEventSpy).not.toHaveBeenCalled();
    });

    describe('clicking on an inactive tab', () => {
      beforeEach(() => {
        findTab('bar').click();
      });

      it('changes the active tab', () => {
        expectActiveTabAndPanel('bar');
      });

      it('deactivates the previously active tab', () => {
        expectInactiveTabAndPanel('foo');
      });

      it(`dispatches a ${TAB_SHOWN_EVENT} event`, () => {
        expectGlTabShownEvent('bar');
      });
    });

    describe('clicking on the active tab', () => {
      beforeEach(() => {
        findTab('foo').click();
      });

      it('does nothing', () => {
        expectActiveTabAndPanel('foo');
        expect(tabShownEventSpy).not.toHaveBeenCalled();
      });
    });

    describe('keyboard navigation', () => {
      it.each(['ArrowRight', 'ArrowDown'])('pressing %s moves to next tab', (code) => {
        expectActiveTabAndPanel('foo');

        triggerKeyDown(code, glTabs.activeTab);

        expectActiveTabAndPanel('bar');
        expectInactiveTabAndPanel('foo');
        expectGlTabShownEvent('bar');
        tabShownEventSpy.mockClear();

        triggerKeyDown(code, glTabs.activeTab);

        expectActiveTabAndPanel('qux');
        expectInactiveTabAndPanel('bar');
        expectGlTabShownEvent('qux');
        tabShownEventSpy.mockClear();

        // We're now on the last tab, so the active tab should not change
        triggerKeyDown(code, glTabs.activeTab);

        expectActiveTabAndPanel('qux');
        expect(tabShownEventSpy).not.toHaveBeenCalled();
      });

      it.each(['ArrowLeft', 'ArrowUp'])('pressing %s moves to previous tab', (code) => {
        // First, make the last tab active
        findTab('qux').click();
        tabShownEventSpy.mockClear();

        // Now start moving backwards
        expectActiveTabAndPanel('qux');

        triggerKeyDown(code, glTabs.activeTab);

        expectActiveTabAndPanel('bar');
        expectInactiveTabAndPanel('qux');
        expectGlTabShownEvent('bar');
        tabShownEventSpy.mockClear();

        triggerKeyDown(code, glTabs.activeTab);

        expectActiveTabAndPanel('foo');
        expectInactiveTabAndPanel('bar');
        expectGlTabShownEvent('foo');
        tabShownEventSpy.mockClear();

        // We're now on the first tab, so the active tab should not change
        triggerKeyDown(code, glTabs.activeTab);

        expectActiveTabAndPanel('foo');
        expect(tabShownEventSpy).not.toHaveBeenCalled();
      });
    });

    describe('destroying', () => {
      beforeEach(() => {
        glTabs.destroy();
      });

      it('removes interactivity', () => {
        const inactiveTab = findTab('bar');

        // clicks do nothing
        inactiveTab.click();
        expectActiveTabAndPanel('foo');
        expect(tabShownEventSpy).not.toHaveBeenCalled();

        // keydown events do nothing
        triggerKeyDown('ArrowDown', inactiveTab);
        expectActiveTabAndPanel('foo');
        expect(tabShownEventSpy).not.toHaveBeenCalled();
      });
    });

    describe('activateTab method', () => {
      it.each`
        tabState      | name
        ${'active'}   | ${'foo'}
        ${'inactive'} | ${'bar'}
      `('can programmatically activate an $tabState tab', ({ name }) => {
        glTabs.activateTab(findTab(name));
        expectActiveTabAndPanel(name);
        expectGlTabShownEvent(name, 'foo');
      });
    });
  });

  describe('using aria-controls instead of href to link tabs to panels', () => {
    beforeEach(() => {
      setHTMLFixture(htmlTabs);

      const tabsEl = findByTestId('tabs');
      ['foo', 'bar', 'qux'].forEach((name) => {
        const tab = findTab(name);
        const panel = findPanel(name);

        tab.setAttribute('href', '#');
        tab.setAttribute('aria-controls', panel.id);
      });

      glTabs = new GlTabsBehavior(tabsEl);
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('connects the panels to their tabs correctly', () => {
      findTab('bar').click();

      expectActiveTabAndPanel('bar');
      expectInactiveTabAndPanel('foo');
    });
  });

  describe('using history=hash', () => {
    const defaultTab = 'foo';
    let tab;
    let tabsEl;

    beforeEach(() => {
      setHTMLFixture(htmlTabs);
      tabsEl = findByTestId('tabs');
    });

    afterEach(() => {
      glTabs.destroy();
      resetHTMLFixture();
    });

    describe('when a hash exists onInit', () => {
      beforeEach(() => {
        tab = 'bar';
        setWindowLocation(`http://foo.com/index#${tab}`);
        glTabs = new GlTabsBehavior(tabsEl, { history: HISTORY_TYPE_HASH });
      });

      it('sets the active tab to the hash and preserves hash', () => {
        expectActiveTabAndPanel(tab);
        expect(getLocationHash()).toBe(tab);
      });
    });

    describe('when a hash does not exist onInit', () => {
      beforeEach(() => {
        setWindowLocation(`http://foo.com/index`);
        glTabs = new GlTabsBehavior(tabsEl, { history: HISTORY_TYPE_HASH });
      });

      it('sets the active tab to the first tab and sets hash', () => {
        expectActiveTabAndPanel(defaultTab);
        expect(getLocationHash()).toBe(defaultTab);
      });
    });

    describe('clicking on an inactive tab', () => {
      beforeEach(() => {
        tab = 'qux';
        setWindowLocation(`http://foo.com/index`);
        glTabs = new GlTabsBehavior(tabsEl, { history: HISTORY_TYPE_HASH });

        findTab(tab).click();
      });

      it('changes the tabs and updates the hash', () => {
        expectInactiveTabAndPanel(defaultTab);
        expectActiveTabAndPanel(tab);
        expect(getLocationHash()).toBe(tab);
      });
    });

    describe('keyboard navigation', () => {
      const secondTab = 'bar';

      beforeEach(() => {
        setWindowLocation(`http://foo.com/index`);
        glTabs = new GlTabsBehavior(tabsEl, { history: HISTORY_TYPE_HASH });
      });

      it.each(['ArrowRight', 'ArrowDown'])(
        'pressing %s moves to next tab and updates hash',
        (code) => {
          expectActiveTabAndPanel(defaultTab);

          triggerKeyDown(code, glTabs.activeTab);

          expectInactiveTabAndPanel(defaultTab);
          expectActiveTabAndPanel(secondTab);
          expect(getLocationHash()).toBe(secondTab);
        },
      );

      it.each(['ArrowLeft', 'ArrowUp'])(
        'pressing %s moves to previous tab and updates hash',
        (code) => {
          // First, make the 2nd tab active
          findTab(secondTab).click();
          expectActiveTabAndPanel(secondTab);

          triggerKeyDown(code, glTabs.activeTab);

          expectInactiveTabAndPanel(secondTab);
          expectActiveTabAndPanel(defaultTab);
          expect(getLocationHash()).toBe(defaultTab);
        },
      );
    });
  });
});
