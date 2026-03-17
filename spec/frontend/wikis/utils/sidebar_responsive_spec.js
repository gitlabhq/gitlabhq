import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { observeSidebarResponsiveness } from '~/wikis/utils/sidebar_responsive';

describe('wikis/utils/sidebar_responsive', () => {
  let onAutoClose;
  let cleanup;

  const createFixture = ({
    sidebarExpanded = true,
    sidebarPosition = 'fixed',
    sidebarRight = 300,
    contentLeft = 200,
  } = {}) => {
    setHTMLFixture(`
      <div class="wiki-sidebar js-wiki-sidebar ${sidebarExpanded ? 'sidebar-expanded' : 'sidebar-collapsed'}">
        <div class="sidebar-container"></div>
      </div>
      <div class="wiki-page-details"></div>
    `);

    const sidebarEl = document.querySelector('.wiki-sidebar');
    const sidebarContainer = sidebarEl.querySelector('.sidebar-container');
    const contentEl = document.querySelector('.wiki-page-details');

    jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: sidebarPosition });
    jest.spyOn(sidebarContainer, 'getBoundingClientRect').mockReturnValue({ right: sidebarRight });
    jest.spyOn(contentEl, 'getBoundingClientRect').mockReturnValue({ left: contentLeft });
  };

  beforeEach(() => {
    onAutoClose = jest.fn();
  });

  afterEach(() => {
    if (cleanup) cleanup();
    cleanup = null;
    resetHTMLFixture();
    jest.restoreAllMocks();
  });

  it('returns a no-op cleanup when elements are missing', () => {
    cleanup = observeSidebarResponsiveness(onAutoClose);

    expect(onAutoClose).not.toHaveBeenCalled();
    expect(cleanup).toEqual(expect.any(Function));
  });

  it('calls onAutoClose when fixed sidebar overlaps content', () => {
    createFixture({ sidebarRight: 300, contentLeft: 200 });

    cleanup = observeSidebarResponsiveness(onAutoClose);

    expect(onAutoClose).toHaveBeenCalled();
  });

  it('does not call onAutoClose when fixed sidebar does not overlap content', () => {
    createFixture({ sidebarRight: 200, contentLeft: 300 });

    cleanup = observeSidebarResponsiveness(onAutoClose);

    expect(onAutoClose).not.toHaveBeenCalled();
  });

  it('does not call onAutoClose when sidebar is not fixed', () => {
    createFixture({ sidebarPosition: 'relative', sidebarRight: 300, contentLeft: 200 });

    cleanup = observeSidebarResponsiveness(onAutoClose);

    expect(onAutoClose).not.toHaveBeenCalled();
  });

  it('does not call onAutoClose when sidebar is collapsed', () => {
    createFixture({ sidebarExpanded: false, sidebarRight: 300, contentLeft: 200 });

    cleanup = observeSidebarResponsiveness(onAutoClose);

    expect(onAutoClose).not.toHaveBeenCalled();
  });

  it('disconnects the ResizeObserver on cleanup', () => {
    createFixture();
    const disconnectSpy = jest.fn();
    jest.spyOn(window, 'ResizeObserver').mockImplementation(() => ({
      observe: jest.fn(),
      disconnect: disconnectSpy,
    }));

    cleanup = observeSidebarResponsiveness(onAutoClose);
    cleanup();
    cleanup = null;

    expect(disconnectSpy).toHaveBeenCalled();
  });
});
