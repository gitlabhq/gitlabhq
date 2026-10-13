import htmlTabs from 'test_fixtures/tabs/tabs.html';
import { GlTabsBehavior, TAB_SHOWN_EVENT, HISTORY_TYPE_HASH } from '~/tabs';
import { ACTIVE_PANEL_CLASS, ACTIVE_TAB_CLASSES } from '~/tabs/constants';
import { getLocationHash } from '~/lib/utils/url_utility';
import { handleLocationHash } from '~/lib/utils/common_utils';
import { NO_SCROLL_TO_HASH_CLASS } from '~/lib/utils/constants';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import setWindowLocation from 'helpers/set_window_location_helper';

jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  handleLocationHash: jest.fn(),
}));

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

  const expectActiveTabAndPanel = (name, instance = glTabs) => {
    const tab = findTab(name);
    const panel = findPanel(name);

    expect(instance.activeTab).toBe(tab);

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

  const expectInactiveTabAndPanel = (name, instance = glTabs) => {
    const tab = findTab(name);
    const panel = findPanel(name);

    expect(instance.activeTab).not.toBe(tab);

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

  const appendElement = (parent, id) => {
    const element = document.createElement('input');
    element.id = id;
    parent.appendChild(element);
    return element;
  };

  const triggerHashChange = (hash) => {
    setWindowLocation(`http://foo.com/index#${hash}`);
    window.dispatchEvent(new Event('hashchange'));
  };

  // Adds a copy of the fixture whose ids, hrefs and test ids carry `prefix`.
  const appendTabSet = (parent, prefix) => {
    parent.insertAdjacentHTML(
      'beforeend',
      htmlTabs.replace(/(href="#|id="|data-testid=")/g, `$1${prefix}-`),
    );
    return findByTestId(`${prefix}-tabs`);
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
        inactiveTab.addEventListener('click', (e) => e.preventDefault(), { once: true });
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

    describe('revealElement method', () => {
      it('activates the tab whose panel contains the element', () => {
        const element = appendElement(findPanel('qux'), 'deep-link');

        expect(glTabs.revealElement(element)).toBe(true);
        expectActiveTabAndPanel('qux');
        expectGlTabShownEvent('qux');
      });

      it('does nothing for an element in the active panel', () => {
        const element = appendElement(findPanel('foo'), 'deep-link');

        expect(glTabs.revealElement(element)).toBe(true);
        expectActiveTabAndPanel('foo');
        expect(tabShownEventSpy).not.toHaveBeenCalled();
      });

      it.each`
        description                        | element
        ${'an element outside the panels'} | ${() => appendElement(document.body, 'outside')}
        ${'null'}                          | ${() => null}
      `('returns false for $description', ({ element }) => {
        expect(glTabs.revealElement(element())).toBe(false);
        expectActiveTabAndPanel('foo');
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
    let tabsEl;

    const initTabs = (el = tabsEl) => new GlTabsBehavior(el, { history: HISTORY_TYPE_HASH });

    beforeEach(() => {
      setHTMLFixture(htmlTabs);
      tabsEl = findByTestId('tabs');
    });

    afterEach(() => {
      glTabs.destroy();
      resetHTMLFixture();
    });

    describe('on init', () => {
      describe('when there is no hash', () => {
        beforeEach(() => {
          setWindowLocation('http://foo.com/index');
          tabShownEventSpy = jest.fn();
          tabsEl.addEventListener(TAB_SHOWN_EVENT, tabShownEventSpy);
          glTabs = initTabs();
        });

        it('activates the first tab and writes its hash', () => {
          expectActiveTabAndPanel(defaultTab);
          expect(getLocationHash()).toBe(defaultTab);
        });

        it(`fires ${TAB_SHOWN_EVENT} for the initial tab`, () => {
          expectGlTabShownEvent(defaultTab);
        });
      });

      describe('when the hash names a tab', () => {
        beforeEach(() => {
          setWindowLocation('http://foo.com/index#bar');
          glTabs = initTabs();
        });

        it('activates that tab and keeps the hash', () => {
          expectActiveTabAndPanel('bar');
          expect(getLocationHash()).toBe('bar');
        });
      });

      describe('when the hash names nothing', () => {
        beforeEach(() => {
          setWindowLocation('http://foo.com/index#nope');
          glTabs = initTabs();
        });

        it('activates the first tab and replaces the hash', () => {
          expectActiveTabAndPanel(defaultTab);
          expect(getLocationHash()).toBe(defaultTab);
        });
      });

      describe('when the hash names an element inside an inactive panel', () => {
        beforeEach(() => {
          appendElement(findPanel('qux'), 'deep-link');
          setWindowLocation('http://foo.com/index#deep-link');
          glTabs = initTabs();
        });

        it('activates that panel and keeps the hash', () => {
          expectActiveTabAndPanel('qux');
          expectInactiveTabAndPanel(defaultTab);
          expect(getLocationHash()).toBe('deep-link');
        });
      });

      describe('when the hash names a percent-encoded element id', () => {
        beforeEach(() => {
          appendElement(findPanel('qux'), 'deep link');
          setWindowLocation('http://foo.com/index#deep%20link');
          glTabs = initTabs();
        });

        it('decodes the hash to find the element', () => {
          expectActiveTabAndPanel('qux');
          expect(getLocationHash()).toBe('deep%20link');
        });
      });

      describe('when the hash is malformed', () => {
        beforeEach(() => {
          setWindowLocation('http://foo.com/index#%E0%A4%A');
          glTabs = initTabs();
        });

        it('falls back to the first tab without throwing', () => {
          expectActiveTabAndPanel(defaultTab);
        });
      });

      describe('when the hash names an element outside the panels', () => {
        beforeEach(() => {
          appendElement(document.body, 'outside');
          setWindowLocation('http://foo.com/index#outside');
          glTabs = initTabs();
        });

        it('keeps the first tab and leaves the hash alone', () => {
          expectActiveTabAndPanel(defaultTab);
          expect(getLocationHash()).toBe('outside');
        });
      });
    });

    describe('on hashchange', () => {
      beforeEach(() => {
        appendElement(findPanel('qux'), 'deep-link');
        appendElement(document.body, 'outside');
        setWindowLocation('http://foo.com/index');
        glTabs = initTabs();

        tabShownEventSpy = jest.fn();
        tabsEl.addEventListener(TAB_SHOWN_EVENT, tabShownEventSpy);
        handleLocationHash.mockClear();
      });

      describe('when the hash names an inactive tab', () => {
        beforeEach(() => {
          triggerHashChange('bar');
        });

        it('activates that tab', () => {
          expectActiveTabAndPanel('bar');
          expectInactiveTabAndPanel(defaultTab);
          expect(getLocationHash()).toBe('bar');
          expectGlTabShownEvent('bar');
          expect(handleLocationHash).not.toHaveBeenCalled();
        });
      });

      describe('when the hash names the active tab', () => {
        beforeEach(() => {
          triggerHashChange(defaultTab);
        });

        it('does nothing', () => {
          expectActiveTabAndPanel(defaultTab);
          expect(tabShownEventSpy).not.toHaveBeenCalled();
          expect(handleLocationHash).not.toHaveBeenCalled();
        });
      });

      describe('when the hash names an element inside an inactive panel', () => {
        beforeEach(() => {
          triggerHashChange('deep-link');
        });

        it('activates that panel, keeps the hash and scrolls again', () => {
          expectActiveTabAndPanel('qux');
          expect(getLocationHash()).toBe('deep-link');
          expect(handleLocationHash).toHaveBeenCalledTimes(1);
        });
      });

      describe('when the hash names an element outside the panels', () => {
        beforeEach(() => {
          triggerHashChange('outside');
        });

        it('does nothing', () => {
          expectActiveTabAndPanel(defaultTab);
          expect(getLocationHash()).toBe('outside');
          expect(handleLocationHash).not.toHaveBeenCalled();
        });
      });

      describe('when the hash names nothing', () => {
        beforeEach(() => {
          triggerHashChange('nope');
        });

        it('does nothing', () => {
          expectActiveTabAndPanel(defaultTab);
          expect(getLocationHash()).toBe('nope');
        });
      });

      describe('after destroy', () => {
        beforeEach(() => {
          glTabs.destroy();
          triggerHashChange('bar');
        });

        it('does nothing', () => {
          expectActiveTabAndPanel(defaultTab);
        });
      });
    });

    describe('with a second tab set nested inside a panel', () => {
      let innerTabs;

      const initBoth = () => {
        glTabs = initTabs();
        innerTabs = initTabs(findByTestId('inner-tabs'));
      };

      beforeEach(() => {
        appendTabSet(findPanel('qux'), 'inner');
      });

      afterEach(() => {
        innerTabs.destroy();
      });

      describe('when the hash names an inner tab on init', () => {
        beforeEach(() => {
          setWindowLocation('http://foo.com/index#inner-bar');
          initBoth();
        });

        it('activates the enclosing outer tab and the inner tab', () => {
          expectActiveTabAndPanel('qux');
          expectActiveTabAndPanel('inner-bar', innerTabs);
          expect(getLocationHash()).toBe('inner-bar');
        });
      });

      describe('when the hash names an element inside an inner panel on init', () => {
        beforeEach(() => {
          appendElement(findPanel('inner-bar'), 'deep-link');
          setWindowLocation('http://foo.com/index#deep-link');
          initBoth();
        });

        it('activates both enclosing tabs and keeps the hash', () => {
          expectActiveTabAndPanel('qux');
          expectActiveTabAndPanel('inner-bar', innerTabs);
          expect(getLocationHash()).toBe('deep-link');
        });
      });

      describe('when the hash names an outer tab on init', () => {
        beforeEach(() => {
          setWindowLocation('http://foo.com/index#bar');
          initBoth();
        });

        it('activates the outer tab and leaves the inner tabs alone', () => {
          expectActiveTabAndPanel('bar');
          expectActiveTabAndPanel('inner-foo', innerTabs);
          expect(getLocationHash()).toBe('bar');
        });
      });

      describe('when the hash changes to an inner tab', () => {
        beforeEach(() => {
          setWindowLocation('http://foo.com/index');
          initBoth();
          handleLocationHash.mockClear();
          triggerHashChange('inner-bar');
        });

        it('activates the enclosing outer tab, then the inner tab', () => {
          expectActiveTabAndPanel('qux');
          expectActiveTabAndPanel('inner-bar', innerTabs);
          expect(getLocationHash()).toBe('inner-bar');
          expect(handleLocationHash).toHaveBeenCalledTimes(1);
        });
      });

      describe('revealElement', () => {
        beforeEach(() => {
          setWindowLocation('http://foo.com/index');
          initBoth();
        });

        it('does not let the inner tabs claim an element in an outer panel', () => {
          expect(innerTabs.revealElement(appendElement(findPanel('bar'), 'outer-field'))).toBe(
            false,
          );
          expectActiveTabAndPanel('inner-foo', innerTabs);
        });

        it('lets the outer tabs reveal an element in an inner panel', () => {
          expect(glTabs.revealElement(appendElement(findPanel('inner-bar'), 'inner-field'))).toBe(
            true,
          );
          expectActiveTabAndPanel('qux');
        });
      });
    });

    describe('with a second tab set next to the first', () => {
      let secondTabs;

      beforeEach(() => {
        appendTabSet(tabsEl.parentElement, 'second');
      });

      afterEach(() => {
        secondTabs.destroy();
      });

      describe('when the hash names a tab of the second set on init', () => {
        beforeEach(() => {
          setWindowLocation('http://foo.com/index#second-bar');
          glTabs = initTabs();
          secondTabs = initTabs(findByTestId('second-tabs'));
        });

        it('activates it in the second set only and keeps the hash', () => {
          expectActiveTabAndPanel(defaultTab);
          expectActiveTabAndPanel('second-bar', secondTabs);
          expect(getLocationHash()).toBe('second-bar');
        });
      });

      describe('when the hash changes to an element inside a panel of the second set', () => {
        beforeEach(() => {
          appendElement(findPanel('second-qux'), 'deep-link');
          setWindowLocation('http://foo.com/index');
          glTabs = initTabs();
          secondTabs = initTabs(findByTestId('second-tabs'));
          handleLocationHash.mockClear();
          triggerHashChange('deep-link');
        });

        it('activates that panel in the second set only and scrolls again', () => {
          expectActiveTabAndPanel(defaultTab);
          expectActiveTabAndPanel('second-qux', secondTabs);
          expect(getLocationHash()).toBe('deep-link');
          expect(handleLocationHash).toHaveBeenCalledTimes(1);
        });
      });
    });

    describe('activateTab with updateHistory: false', () => {
      beforeEach(() => {
        setWindowLocation('http://foo.com/index#bar');
        glTabs = initTabs();
      });

      it('activates the tab and keeps the current hash', () => {
        glTabs.activateTab(findTab('qux'), { updateHistory: false });

        expectActiveTabAndPanel('qux');
        expect(getLocationHash()).toBe('bar');
      });

      it('is used by revealElement', () => {
        glTabs.revealElement(appendElement(findPanel('qux'), 'deep-link'));

        expectActiveTabAndPanel('qux');
        expect(getLocationHash()).toBe('bar');
      });
    });

    describe('clicking on an inactive tab', () => {
      beforeEach(() => {
        setWindowLocation('http://foo.com/index');
        glTabs = initTabs();

        findTab('qux').click();
      });

      it('changes the tabs and updates the hash', () => {
        expectInactiveTabAndPanel(defaultTab);
        expectActiveTabAndPanel('qux');
        expect(getLocationHash()).toBe('qux');
      });
    });

    describe('keyboard navigation', () => {
      const secondTab = 'bar';

      beforeEach(() => {
        setWindowLocation('http://foo.com/index');
        glTabs = initTabs();
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
