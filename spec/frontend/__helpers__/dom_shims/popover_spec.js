describe('DOM patch for the Popover API', () => {
  let el;
  let toggleEvents;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('popover', 'manual');
    document.body.appendChild(el);

    toggleEvents = [];
    el.addEventListener('toggle', ({ oldState, newState }) =>
      toggleEvents.push([oldState, newState]),
    );
  });

  afterEach(() => {
    el.remove();
  });

  it('shows and hides the popover', () => {
    el.showPopover();
    expect(el.matches(':popover-open')).toBe(true);

    el.hidePopover();
    expect(el.matches(':popover-open')).toBe(false);
  });

  it('dispatches a toggle event for each change only', () => {
    el.showPopover();
    el.showPopover();
    el.hidePopover();
    el.hidePopover();

    expect(toggleEvents).toEqual([
      ['closed', 'open'],
      ['open', 'closed'],
    ]);
  });

  it('toggles the popover and returns whether it is now open', () => {
    expect(el.togglePopover()).toBe(true);
    expect(el.matches(':popover-open')).toBe(true);

    expect(el.togglePopover(true)).toBe(true);
    expect(el.matches(':popover-open')).toBe(true);

    expect(el.togglePopover(false)).toBe(false);
    expect(el.matches(':popover-open')).toBe(false);
  });

  it.each(['showPopover', 'hidePopover'])(
    'throws NotSupportedError from %s without a popover attribute',
    (method) => {
      el.removeAttribute('popover');

      expect(() => el[method]()).toThrow(expect.objectContaining({ name: 'NotSupportedError' }));
    },
  );

  it('keeps matching other selectors', () => {
    el.classList.add('foo');

    expect(el.matches('.foo')).toBe(true);
    expect(el.matches('.bar')).toBe(false);
  });
});
