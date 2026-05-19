import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initClonePanel from '~/clone_panel';

describe('initClonePanel', () => {
  const cloneUrlHttp = 'https://example.com/group/project.git';
  const cloneUrlSsh = 'git@example.com:group/project.git';
  const cloneUrlVscode = 'vscode://vscode.git/clone?url=https://example.com/group/project.git';

  const setupFixture = ({ initialLabel = 'HTTPS', withMobile = false } = {}) => {
    setHTMLFixture(`
      <div class="js-git-clone-holder">
        <span class="js-clone-dropdown-label">${initialLabel}</span>
        <ul class="clone-options-dropdown">
          <li class="js-clone-links">
            <a href="${cloneUrlSsh}" data-clone-type="ssh">
              <span class="dropdown-menu-inner-title">SSH</span>
            </a>
          </li>
          <li class="js-clone-links">
            <a href="${cloneUrlHttp}" data-clone-type="http">
              <span class="dropdown-menu-inner-title">HTTPS</span>
            </a>
          </li>
          <li class="js-clone-links">
            <a href="${cloneUrlVscode}" data-clone-type="vscode">
              <span class="dropdown-menu-inner-title">Visual Studio Code (HTTPS)</span>
            </a>
          </li>
        </ul>
        <input id="clone_url" value="${cloneUrlHttp}" />
      </div>
      ${
        withMobile
          ? `
        <div class="js-mobile-git-clone">
          <button class="js-clone-dropdown-label" data-clipboard-text="${cloneUrlHttp}">HTTPS</button>
          <ul class="clone-options-dropdown">
            <li class="js-clone-links">
              <a href="${cloneUrlSsh}" data-clone-type="ssh">
                <span class="dropdown-menu-inner-title">SSH</span>
              </a>
            </li>
            <li class="js-clone-links">
              <a href="${cloneUrlHttp}" data-clone-type="http">
                <span class="dropdown-menu-inner-title">HTTPS</span>
              </a>
            </li>
          </ul>
        </div>
      `
          : ''
      }
      <div class="js-git-empty">
        <span class="js-clone"></span>
      </div>
    `);
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  it('does nothing when there is no clone-options dropdown', () => {
    setHTMLFixture('<div></div>');
    expect(() => initClonePanel()).not.toThrow();
  });

  it('marks the anchor matching the current label as active on init', () => {
    setupFixture({ initialLabel: 'SSH' });
    initClonePanel();

    const sshAnchor = document.querySelector('a[data-clone-type="ssh"]');
    const httpAnchor = document.querySelector('a[data-clone-type="http"]');
    expect(sshAnchor.classList.contains('is-active')).toBe(true);
    expect(httpAnchor.classList.contains('is-active')).toBe(false);
  });

  it('switches active state, label, and clone URL on click', () => {
    setupFixture({ initialLabel: 'HTTPS' });
    initClonePanel();

    document.querySelector('a[data-clone-type="ssh"]').click();

    expect(document.querySelector('a[data-clone-type="ssh"]').classList.contains('is-active')).toBe(
      true,
    );
    expect(
      document.querySelector('a[data-clone-type="http"]').classList.contains('is-active'),
    ).toBe(false);
    expect(document.querySelector('.js-clone-dropdown-label').textContent).toBe('SSH');
    expect(document.getElementById('clone_url').value).toBe(cloneUrlSsh);
    expect(document.querySelector('.js-git-empty .js-clone').textContent).toBe(cloneUrlSsh);
  });

  it('updates both desktop and mobile labels when present', () => {
    setupFixture({ initialLabel: 'HTTPS', withMobile: true });
    initClonePanel();

    document.querySelector('.js-git-clone-holder a[data-clone-type="ssh"]').click();

    const labels = document.querySelectorAll('.js-clone-dropdown-label');
    labels.forEach((label) => {
      expect(label.textContent).toBe('SSH');
    });
  });

  it('writes clone URL to mobile clipboard-text when mobile field exists, not to #clone_url', () => {
    setupFixture({ initialLabel: 'HTTPS', withMobile: true });
    initClonePanel();

    document.querySelector('.js-git-clone-holder a[data-clone-type="ssh"]').click();

    const mobileLabel = document.querySelector('.js-mobile-git-clone .js-clone-dropdown-label');
    expect(mobileLabel.dataset.clipboardText).toBe(cloneUrlSsh);
    expect(document.getElementById('clone_url').value).toBe(cloneUrlHttp);
  });

  it('does not preventDefault when link is an editor protocol (vscode/xcode/jetbrains)', () => {
    setupFixture({ initialLabel: 'HTTPS' });
    initClonePanel();

    // Capture the handler's preventDefault state in a doc-level bubble
    // listener, then preventDefault ourselves so jsdom skips its activation
    // behavior. Without this, jsdom logs "Not implemented: navigation" for
    // vscode:// asynchronously, which leaks into adjacent specs in the shard.
    let preventedByHandler;
    document.addEventListener(
      'click',
      (event) => {
        preventedByHandler = event.defaultPrevented;
        event.preventDefault();
      },
      { once: true },
    );

    document.querySelector('a[data-clone-type="vscode"]').click();

    expect(preventedByHandler).toBe(false);
    expect(document.getElementById('clone_url').value).toBe(cloneUrlHttp);
  });

  it('preventsDefault for regular http/ssh clone links', () => {
    setupFixture({ initialLabel: 'HTTPS' });
    initClonePanel();

    const anchor = document.querySelector('a[data-clone-type="ssh"]');
    const event = new MouseEvent('click', { bubbles: true, cancelable: true });
    anchor.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
  });
});
