import { nextTick } from 'vue';
import { GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import FocusCarousel, {
  WHEEL_GESTURE_GAP_MS,
  WHEEL_REFRACTORY_MS,
} from '~/vue_shared/components/focus_carousel/focus_carousel.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const buildItem = (n, overrides = {}) => ({
  id: `item-${n}`,
  title: `Item ${n}`,
  timestamp: '2026-08-18T09:00:00.000Z',
  meta: ['Duo UI', 'Software development'],
  summary: `Summary for item ${n}`,
  status: { text: 'Running', variant: 'info', icon: 'play' },
  href: `https://gitlab.example.com/items/${n}`,
  ...overrides,
});

describe('FocusCarousel', () => {
  let wrapper;

  const items = [1, 2, 3, 4].map((n) => buildItem(n));

  const createComponent = ({ props = {}, attachTo } = {}) => {
    wrapper = mountExtended(FocusCarousel, {
      propsData: {
        items,
        regionLabel: 'Recent items',
        emptyStateText: 'No recent items',
        ...props,
      },
      attachTo,
    });
  };

  const findRoot = () => wrapper.findByTestId('focus-carousel');
  const findFocusCard = () => wrapper.findByTestId('focus-carousel-focus');
  const findPrevItem = () => wrapper.findByTestId('focus-carousel-prev');
  const findNextItems = () => wrapper.findAllByTestId('focus-carousel-next-item');
  const findCounter = () => wrapper.findByTestId('focus-carousel-counter');
  const findOpenButton = () => wrapper.findByTestId('focus-carousel-open');
  const findAnnouncement = () => wrapper.findByTestId('focus-carousel-announcement');
  const findEmptyState = () => wrapper.findByTestId('focus-carousel-empty');
  const findMetaEntries = () => wrapper.findAllByTestId('focus-carousel-meta');
  const findFocusTitle = () => findFocusCard().find('h3');
  const findStatusBadge = () => findFocusCard().findComponent(GlBadge);

  const pressKey = (key) => findRoot().trigger('keydown', { key });

  const wheel = async (deltaY, options = {}) => {
    const event = new WheelEvent('wheel', { deltaY, bubbles: true, cancelable: true, ...options });
    findRoot().element.dispatchEvent(event);
    await nextTick();
    return event;
  };

  describe('items prop validation', () => {
    const { validator } = FocusCarousel.props.items;

    it('accepts items carrying an id and a title', () => {
      expect(validator([buildItem(1), { id: 0, title: 'Bare minimum' }])).toBe(true);
    });

    it.each`
      description          | invalid
      ${'a missing id'}    | ${{ title: 'No id' }}
      ${'a missing title'} | ${{ id: 'no-title' }}
      ${'a null element'}  | ${null}
    `('rejects a list containing $description', ({ invalid }) => {
      expect(validator([buildItem(1), invalid])).toBe(false);
    });

    it('rejects duplicate ids, which would mis-route focus', () => {
      expect(validator([buildItem(1), buildItem(1)])).toBe(false);
    });
  });

  describe('initial render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a labelled, keyboard-reachable group', () => {
      expect(findRoot().attributes()).toMatchObject({
        role: 'group',
        'aria-label': 'Recent items',
        'aria-roledescription': 'carousel',
        tabindex: '0',
      });
      // Operation keys of a focused composite are not aria-keyshortcuts
      // material (that property announces activation shortcuts), so the
      // group carries none.
      expect(findRoot().attributes('aria-keyshortcuts')).toBeUndefined();
    });

    it('focuses the first item and renders no previous item', () => {
      expect(findFocusTitle().text()).toBe('Item 1');
      expect(findPrevItem().exists()).toBe(false);
    });

    it('renders the next two items only', () => {
      expect(findNextItems()).toHaveLength(2);
      expect(findNextItems().at(0).text()).toContain('Item 2');
      expect(findNextItems().at(1).text()).toContain('Item 3');
    });

    it('renders the up-next header and the counter', () => {
      expect(wrapper.text()).toContain('Up next');
      expect(findCounter().text()).toBe('1 of 4');
    });

    it('renders an empty live region: only navigation announces, not the initial card', () => {
      expect(findAnnouncement().attributes()).toMatchObject({
        'aria-live': 'polite',
        'aria-atomic': 'true',
      });
      expect(findAnnouncement().text()).toBe('');
    });
  });

  describe('focus card contents', () => {
    it('renders status, timestamp, and meta entries in the meta line', () => {
      createComponent();

      expect(findStatusBadge().props()).toMatchObject({ variant: 'info', icon: 'play' });
      expect(wrapper.findByTestId('focus-carousel-status').text()).toBe('Running');
      expect(findFocusCard().findComponent(TimeAgoTooltip).props('time')).toBe(
        '2026-08-18T09:00:00.000Z',
      );
      expect(findMetaEntries().wrappers.map((w) => w.text())).toEqual([
        'Duo UI',
        'Software development',
      ]);
      expect(wrapper.findByTestId('focus-carousel-summary').text()).toBe('Summary for item 1');
    });

    it('omits the optional fields when they are absent', () => {
      createComponent({
        props: { items: [buildItem(1, { meta: undefined, summary: null, status: null })] },
      });

      expect(findMetaEntries()).toHaveLength(0);
      expect(findStatusBadge().exists()).toBe(false);
      expect(wrapper.findByTestId('focus-carousel-summary').exists()).toBe(false);
    });

    it('separates the meta line without doubled dots when the timestamp is absent', () => {
      createComponent({
        props: { items: [buildItem(1, { timestamp: null, meta: ['Only meta'] })] },
      });

      const line = findFocusCard().find('.gl-mt-3').text().replace(/\s+/g, ' ');

      expect(line).toBe('Running · Only meta');
    });
  });

  describe('keyboard navigation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('moves focus forward on ArrowDown', async () => {
      await pressKey('ArrowDown');

      expect(findFocusTitle().text()).toBe('Item 2');
      expect(findPrevItem().text()).toContain('Item 1');
      expect(findCounter().text()).toBe('2 of 4');
      expect(findAnnouncement().text()).toBe('Item 2 of 4: Item 2, Running');
    });

    it('moves focus backward on ArrowUp', async () => {
      await pressKey('ArrowDown');
      await pressKey('ArrowUp');

      expect(findFocusTitle().text()).toBe('Item 1');
      expect(findPrevItem().exists()).toBe(false);
    });

    it('does not move past the first item', async () => {
      await pressKey('ArrowUp');

      expect(findFocusTitle().text()).toBe('Item 1');
    });

    it('does not move past the last item and drops the empty up-next list', async () => {
      await pressKey('End');
      await pressKey('ArrowDown');

      expect(findFocusTitle().text()).toBe('Item 4');
      expect(findNextItems()).toHaveLength(0);
      expect(findRoot().find('ul').exists()).toBe(false);
    });

    it('jumps to the last item on End and back to the first on Home', async () => {
      await pressKey('End');

      expect(findFocusTitle().text()).toBe('Item 4');
      expect(findCounter().text()).toBe('4 of 4');

      await pressKey('Home');

      expect(findFocusTitle().text()).toBe('Item 1');
      expect(findCounter().text()).toBe('1 of 4');
    });

    it('announces without a status clause when the item has no status', async () => {
      createComponent({ props: { items: [buildItem(1), buildItem(2, { status: null })] } });
      await pressKey('ArrowDown');

      expect(findAnnouncement().text()).toBe('Item 2 of 2: Item 2');
    });

    it('announces titles with apostrophes and angle brackets as written, not as entities', async () => {
      createComponent({
        props: {
          items: [buildItem(1), buildItem(2, { title: "Don't merge <script> changes" })],
        },
      });
      await pressKey('ArrowDown');

      expect(findAnnouncement().text()).toBe("Item 2 of 2: Don't merge <script> changes, Running");
    });

    it('ignores keys bubbling from elements inside the group', async () => {
      // Navigating from a bubbled keydown would move the carousel out from
      // under the element the user is standing on and then yank their focus.
      await findOpenButton().trigger('keydown', { key: 'ArrowDown' });

      expect(findFocusTitle().text()).toBe('Item 1');

      await findNextItems().at(0).trigger('keydown', { key: 'End' });

      expect(findFocusTitle().text()).toBe('Item 1');
    });

    it('ignores modified keys, which belong to the browser', async () => {
      await findRoot().trigger('keydown', { key: 'ArrowDown', ctrlKey: true });

      expect(findFocusTitle().text()).toBe('Item 1');
    });

    it('emits change with the newly focused item on navigation', async () => {
      await pressKey('ArrowDown');

      expect(wrapper.emitted('change')).toEqual([[items[1]]]);
    });

    it('does not re-announce when a refresh reshuffles the list without navigation', async () => {
      await pressKey('ArrowDown');

      expect(findAnnouncement().text()).toBe('Item 2 of 4: Item 2, Running');

      await wrapper.setProps({ items: items.slice(1) });

      expect(findAnnouncement().text()).toBe('Item 2 of 4: Item 2, Running');
    });
  });

  describe('opening from the group', () => {
    it('opens the focused item from state on Enter, immune to the card swap', async () => {
      createComponent();

      // Navigate first: mid-transition the rendered link is the outgoing
      // card's, which is why activation must derive from focusItem.
      await pressKey('ArrowDown');
      await pressKey('Enter');

      expect(visitUrl).toHaveBeenCalledWith('https://gitlab.example.com/items/2');
      expect(wrapper.emitted('open')).toBeUndefined();
    });

    it('emits open for the focused actionable item on Enter', async () => {
      const item = buildItem(1, { href: null, actionable: true });
      createComponent({ props: { items: [item, buildItem(2)] } });

      await pressKey('Enter');

      expect(wrapper.emitted('open')).toEqual([[item]]);
    });

    it('leaves Enter alone when the focused item has no action', async () => {
      createComponent({ props: { items: [buildItem(1, { href: null }), buildItem(2)] } });

      const event = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true, cancelable: true });
      findRoot().element.dispatchEvent(event);
      await nextTick();

      expect(event.defaultPrevented).toBe(false);
      expect(wrapper.emitted('open')).toBeUndefined();
    });

    it('returns focus to the group on Escape from an interior stop', async () => {
      createComponent({ attachTo: document.body });
      findOpenButton().element.focus();

      await findOpenButton().trigger('keydown', { key: 'Escape' });

      expect(document.activeElement).toBe(findRoot().element);
    });

    it('does not claim Escape on the group itself, leaving it to the surface above', async () => {
      createComponent();

      const event = new KeyboardEvent('keydown', {
        key: 'Escape',
        bubbles: true,
        cancelable: true,
      });
      findRoot().element.dispatchEvent(event);
      await nextTick();

      expect(event.defaultPrevented).toBe(false);
    });

    it('does not claim Escape from a single-item interior stop: there is no stop to return to', async () => {
      createComponent({ props: { items: [buildItem(1)] }, attachTo: document.body });
      findOpenButton().element.focus();

      const event = new KeyboardEvent('keydown', {
        key: 'Escape',
        bubbles: true,
        cancelable: true,
      });
      findOpenButton().element.dispatchEvent(event);
      await nextTick();

      expect(event.defaultPrevented).toBe(false);
      expect(document.activeElement).toBe(findOpenButton().element);
    });
  });

  describe('click navigation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('jumps focus to a clicked up-next item instead of navigating', async () => {
      await findNextItems().at(1).trigger('click');

      expect(findFocusTitle().text()).toBe('Item 3');
      expect(wrapper.emitted('open')).toBeUndefined();
    });

    it('jumps focus back to the clicked previous item', async () => {
      await pressKey('ArrowDown');
      await findPrevItem().trigger('click');

      expect(findFocusTitle().text()).toBe('Item 1');
    });
  });

  describe('rail rows', () => {
    beforeEach(() => {
      createComponent();
    });

    it('stays out of the tab order: pointer shortcuts, arrows are the keyboard path', async () => {
      expect(findNextItems().at(0).attributes('tabindex')).toBe('-1');

      await pressKey('ArrowDown');

      expect(findPrevItem().attributes('tabindex')).toBe('-1');
    });

    it('reads title-first so the accessible name leads with the title', () => {
      expect(findNextItems().at(0).text()).toMatch(/^Item 2/);
    });

    it('renders the timestamp as plain relative time, not a focusable tooltip', () => {
      const railTime = findNextItems().at(0).find('time');

      expect(railTime.exists()).toBe(true);
      expect(railTime.attributes('tabindex')).toBeUndefined();
      expect(findNextItems().at(0).findComponent(TimeAgoTooltip).exists()).toBe(false);
    });
  });

  describe('wheel navigation', () => {
    // Steps are decided per gesture from the event stream's shape, so these
    // tests pin the clock per event instead of running timers.
    let nowMs;
    const wheelAt = (at, deltaY) => {
      nowMs = at;
      return wheel(deltaY);
    };

    beforeEach(() => {
      createComponent();
      nowMs = 0;
      jest.spyOn(performance, 'now').mockImplementation(() => nowMs);
    });

    it('ignores a wheel event below the delta threshold', async () => {
      await wheelAt(0, 4);

      expect(findFocusTitle().text()).toBe('Item 1');
    });

    it('steps once for a single notch', async () => {
      await wheelAt(0, 120);

      expect(findFocusTitle().text()).toBe('Item 2');
    });

    it('steps again for a deliberate follow-up gesture after a quiet gap', async () => {
      await wheelAt(0, 120);
      await wheelAt(WHEEL_REFRACTORY_MS + WHEEL_GESTURE_GAP_MS, 120);

      expect(findFocusTitle().text()).toBe('Item 3');
    });

    it('steps once for a long inertial flick, decay tail and all', async () => {
      const tail = [130, 107, 87, 72, 59, 48, 40, 32, 26, 21, 17, 14, 11, 9, 7];
      for (const [index, deltaY] of tail.entries()) {
        // eslint-disable-next-line no-await-in-loop
        await wheelAt(index * 60, deltaY);
      }

      expect(findFocusTitle().text()).toBe('Item 2');
    });

    it('absorbs the ramp-up of the gesture that just stepped', async () => {
      await wheelAt(0, 40);
      await wheelAt(16, 80);
      await wheelAt(32, 130);
      await wheelAt(48, 110);

      expect(findFocusTitle().text()).toBe('Item 2');
    });

    it('steps when a new push rises out of a dying tail', async () => {
      await wheelAt(0, 120);
      await wheelAt(60, 50);
      await wheelAt(120, 30);
      await wheelAt(180, 15);
      await wheelAt(240, 110);

      expect(findFocusTitle().text()).toBe('Item 3');
    });

    it('steps on a direction flip without waiting out a gap', async () => {
      await wheelAt(0, 120);

      expect(findFocusTitle().text()).toBe('Item 2');

      await wheelAt(WHEEL_REFRACTORY_MS + 40, -90);

      expect(findFocusTitle().text()).toBe('Item 1');
    });

    it('treats repeated full-size notches as separate gestures once the refractory passes', async () => {
      await wheelAt(0, 120);
      await wheelAt(100, 120);
      await wheelAt(200, 120);

      // The 100ms notch lands inside the refractory window; the 200ms one steps.
      expect(findFocusTitle().text()).toBe('Item 3');
    });

    it('normalizes line-mode wheel deltas instead of dropping them', async () => {
      const event = new WheelEvent('wheel', {
        deltaY: 3,
        deltaMode: WheelEvent.DOM_DELTA_LINE,
        bubbles: true,
        cancelable: true,
      });
      findRoot().element.dispatchEvent(event);
      await nextTick();

      expect(findFocusTitle().text()).toBe('Item 2');
    });

    it('claims only the event that steps', async () => {
      const stepping = await wheelAt(0, 120);
      const inertia = await wheelAt(60, 100);

      expect(stepping.defaultPrevented).toBe(true);
      expect(inertia.defaultPrevented).toBe(false);
    });

    it('lets the wheel through to the page at the end of the list', async () => {
      await pressKey('End');
      const event = await wheelAt(1000, 120);

      expect(event.defaultPrevented).toBe(false);
    });

    it('leaves pinch-zoom alone: ctrl-wheel events never step or get claimed', async () => {
      nowMs = 0;
      const event = await wheel(120, { ctrlKey: true });

      expect(findFocusTitle().text()).toBe('Item 1');
      expect(event.defaultPrevented).toBe(false);
    });

    it('ignores horizontal-dominant pans and zero-delta events', async () => {
      nowMs = 0;
      const pan = await wheel(9, { deltaX: -60 });
      const zero = await wheel(0, { deltaX: -40 });

      expect(findFocusTitle().text()).toBe('Item 1');
      expect(pan.defaultPrevented).toBe(false);
      expect(zero.defaultPrevented).toBe(false);
    });

    it('keeps stepping for steady line-mode cranking, where every notch is small', async () => {
      const lineNotch = (at) => {
        nowMs = at;
        const event = new WheelEvent('wheel', {
          deltaY: 3,
          deltaMode: WheelEvent.DOM_DELTA_LINE,
          bubbles: true,
          cancelable: true,
        });
        findRoot().element.dispatchEvent(event);
        return nextTick();
      };

      await lineNotch(0);
      await lineNotch(200);
      await lineNotch(400);

      expect(findFocusTitle().text()).toBe('Item 4');
    });

    it('honors a direction flip inside the refractory window', async () => {
      await wheelAt(0, 120);

      expect(findFocusTitle().text()).toBe('Item 2');

      // The reversal peaks well inside the 160ms refractory; a flip can never
      // be the stepping gesture's own ramp, so it steps anyway.
      await wheelAt(100, -40);

      expect(findFocusTitle().text()).toBe('Item 1');
    });

    it('does not double-step when tail jitter rebounds above sub-threshold dregs', async () => {
      await wheelAt(0, 120);
      await wheelAt(60, 50);
      await wheelAt(120, 30);
      await wheelAt(180, 9);
      await wheelAt(240, 7);
      await wheelAt(300, 10);

      expect(findFocusTitle().text()).toBe('Item 2');
    });
  });

  describe('the action affordance', () => {
    // A real link click makes jsdom schedule an unimplemented navigation on a
    // timer, which logs after the suite ends and fails the console watcher.
    // Cancelled at the element itself: the wrapper is detached, so a
    // document-level listener never sees the click. The component's own
    // handler still runs regardless.
    const swallowNavigation = (event) => event.preventDefault();

    it('renders a real link and leaves navigation to it when the item has an href', async () => {
      createComponent();

      expect(findOpenButton().element.tagName).toBe('A');
      expect(findOpenButton().attributes('href')).toBe('https://gitlab.example.com/items/1');

      findOpenButton().element.addEventListener('click', swallowNavigation);
      await findOpenButton().trigger('click');

      expect(wrapper.emitted('open')).toBeUndefined();
    });

    it('renders a button that emits open for an actionable item without an href', async () => {
      const item = buildItem(1, { href: null, actionable: true });
      createComponent({ props: { items: [item] } });

      expect(findOpenButton().element.tagName).toBe('BUTTON');
      expect(findOpenButton().attributes('href')).toBeUndefined();

      await findOpenButton().trigger('click');

      expect(wrapper.emitted('open')).toEqual([[item]]);
    });

    it('renders no affordance for an item with neither href nor actionable', () => {
      createComponent({ props: { items: [buildItem(1, { href: null })] } });

      expect(findOpenButton().exists()).toBe(false);
    });

    it('renders the default action label with no icon', () => {
      createComponent();

      expect(findOpenButton().text()).toBe('Open');
      expect(wrapper.findComponentByTestId('focus-carousel-open').props('icon')).toBe('');
    });

    it('renders the label and icon the embedder supplies', () => {
      createComponent({ props: { actionLabel: 'Open session', actionIcon: 'tanuki' } });

      expect(findOpenButton().text()).toBe('Open session');
      expect(wrapper.findComponentByTestId('focus-carousel-open').props('icon')).toBe('tanuki');
    });

    it('is described by the focused title, so a tab stop on it carries item context', () => {
      createComponent();

      const titleId = findFocusTitle().attributes('id');

      expect(titleId).toEqual(expect.stringContaining('focus-carousel-title-'));
      expect(findOpenButton().attributes('aria-describedby')).toBe(titleId);
    });
  });

  describe('when the focus index is past the end of a shortened list', () => {
    it('keeps the top item focused when a refresh prepends rows before any navigation', async () => {
      createComponent();

      await wrapper.setProps({ items: [buildItem(0), ...items] });

      expect(findFocusTitle().text()).toBe('Item 1');
      expect(findCounter().text()).toBe('2 of 5');
    });

    it('clears the last announcement when the focused item leaves the list', async () => {
      createComponent();
      await pressKey('ArrowDown');

      expect(findAnnouncement().text()).not.toBe('');

      await wrapper.setProps({ items: [] });

      expect(findAnnouncement().text()).toBe('');
    });

    it('falls back to the first item when the focused item leaves the list', async () => {
      createComponent();
      await pressKey('End');

      await wrapper.setProps({ items: items.slice(0, 2) });

      expect(findFocusTitle().text()).toBe('Item 1');
      expect(findCounter().text()).toBe('1 of 2');
    });

    it('keeps the focused item when other items leave the list', async () => {
      createComponent();
      await pressKey('ArrowDown');

      // Item 1 leaves (actioned elsewhere); Item 2 stays focused even though
      // its index changed.
      await wrapper.setProps({ items: items.slice(1) });

      expect(findFocusTitle().text()).toBe('Item 2');
      expect(findCounter().text()).toBe('1 of 3');
    });
  });

  describe('while loading', () => {
    it('keeps rendered items visible during a refresh instead of blanking to a skeleton', () => {
      createComponent({ props: { items, loading: true } });

      expect(findFocusCard().exists()).toBe(true);
      expect(wrapper.findByTestId('focus-carousel-loading').exists()).toBe(false);
      expect(findRoot().attributes('aria-busy')).toBe('true');
    });

    it('renders a bottom-anchored skeleton instead of the empty state', () => {
      createComponent({ props: { items: [], loading: true } });

      expect(wrapper.findByTestId('focus-carousel-loading').exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
      // Anchored where the content will land, so the view does not jump from
      // center to bottom when the data arrives; the auto-margin anchor (not
      // justify-end) keeps over-height content reachable through the root's
      // own scroll.
      expect(wrapper.findByTestId('focus-carousel-anchor').exists()).toBe(true);
      expect(findRoot().classes()).toContain('gl-overflow-y-auto');
      expect(findRoot().attributes('aria-busy')).toBe('true');
    });
  });

  describe('the heading level', () => {
    it('defaults to h3', () => {
      createComponent();

      expect(findFocusCard().find('h3').exists()).toBe(true);
    });

    it('renders at the level the embedder picks', () => {
      createComponent({ props: { headingLevel: 2 } });

      expect(findFocusCard().find('h2').exists()).toBe(true);
      expect(findFocusCard().find('h3').exists()).toBe(false);
    });
  });

  describe('focus management', () => {
    it('restores focus to the group when the focused rail row is promoted away', async () => {
      createComponent({ attachTo: document.body });
      const row = findNextItems().at(0);
      row.element.focus();

      await row.trigger('click');
      await nextTick();

      expect(document.activeElement).toBe(findRoot().element);
    });

    it('parks focus on the group when a refresh removes the focused item under it', async () => {
      createComponent({ attachTo: document.body });
      findOpenButton().element.focus();

      // Item 1 leaves the list (actioned elsewhere) while its card holds
      // DOM focus; without repair, focus would fall to <body>.
      await wrapper.setProps({ items: items.slice(1) });
      await nextTick();

      expect(document.activeElement).toBe(findRoot().element);
    });

    it('does not steal focus on a wheel over an unfocused carousel', async () => {
      createComponent({ attachTo: document.body });
      const outside = document.createElement('button');
      document.body.appendChild(outside);
      outside.focus();

      await wheel(20);
      await nextTick();

      expect(document.activeElement).toBe(outside);
      outside.remove();
    });
  });

  describe('when there is a single item', () => {
    it('renders the focus card with no navigation chrome and leaves the tab order', () => {
      createComponent({ props: { items: [buildItem(1)] } });

      expect(findFocusCard().exists()).toBe(true);
      expect(findPrevItem().exists()).toBe(false);
      expect(findCounter().exists()).toBe(false);
      // Nothing to operate: a tab stop here would be purposeless and would
      // swallow Home/End from keyboard users, and "carousel" would
      // over-describe a lone card.
      expect(findRoot().attributes('tabindex')).toBeUndefined();
      expect(findRoot().attributes('aria-keyshortcuts')).toBeUndefined();
      expect(findRoot().attributes('aria-roledescription')).toBeUndefined();
    });
  });

  describe('when there are no items', () => {
    beforeEach(() => {
      createComponent({ props: { items: [] } });
    });

    it('renders the empty-state text the embedder supplies, centered', () => {
      expect(findEmptyState().text()).toBe('No recent items');
      expect(findRoot().classes()).toEqual(
        expect.arrayContaining(['gl-items-center', 'gl-justify-center']),
      );
      expect(wrapper.findByTestId('focus-carousel-anchor').exists()).toBe(false);
    });

    it('renders no focus card, no counter, and drops the widget semantics', () => {
      expect(findFocusCard().exists()).toBe(false);
      expect(findCounter().exists()).toBe(false);
      // An empty group is not a carousel; the label alone describes it, and
      // there is nothing to reach or operate.
      expect(findRoot().attributes('aria-roledescription')).toBeUndefined();
      expect(findRoot().attributes('tabindex')).toBeUndefined();
    });
  });

  describe('when the user prefers reduced motion', () => {
    beforeEach(() => {
      jest.spyOn(window, 'matchMedia').mockReturnValue({
        matches: true,
        addEventListener: () => {},
        removeEventListener: () => {},
      });
      createComponent();
    });

    it('reads the preference once, at mount', () => {
      expect(window.matchMedia).toHaveBeenCalledTimes(1);
      expect(window.matchMedia).toHaveBeenCalledWith('(prefers-reduced-motion: reduce)');
    });

    it('still moves focus', async () => {
      await pressKey('ArrowDown');

      expect(findFocusTitle().text()).toBe('Item 2');
    });
  });
});
