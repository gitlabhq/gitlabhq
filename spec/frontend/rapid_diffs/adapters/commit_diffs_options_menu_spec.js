import { createPinia, setActivePinia } from 'pinia';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { commitDiffsOptionsMenuAdapter } from '~/rapid_diffs/adapters/commit_diffs_options_menu';

describe('Commit Diffs File Options Menu Adapter', () => {
  const item1 = { text: 'item 1', href: 'item/1/path' };

  function get(element) {
    const elements = {
      file: () => document.querySelector('diff-file'),
      container: () => get('file').querySelector('[data-options-menu]'),
      serverButton: () => get('container').querySelector('[data-click="toggleOptionsMenu"]'),
      vueButton: () => get('container').querySelector('[data-testid="base-dropdown-toggle"]'),
      menuItems: () =>
        get('container').querySelectorAll('[data-testid="disclosure-dropdown-item"]'),
    };

    return elements[element]?.();
  }

  const delegatedClick = (element) => {
    let event;
    element.addEventListener(
      'click',
      (e) => {
        event = e;
      },
      { once: true },
    );
    element.click();
    get('file').onClick(event);
  };

  const mount = (items = [item1]) => {
    const viewer = 'any';
    document.body.innerHTML = `
      <diff-file data-file-data='${JSON.stringify({ viewer })}'>
        <div class="rd-diff-file">
          <div class="rd-diff-file-header">
            <div class="rd-diff-file-options-menu">
              <div data-options-menu>
                <script type="application/json">
                  ${JSON.stringify(items)}
                </script>
                <button data-click="toggleOptionsMenu" type="button"></button>
              </div>
            </div>
            <div></div>
          </div>
        </div>
      </diff-file>
    `;
    get('file').mount({
      adapterConfig: { [viewer]: [commitDiffsOptionsMenuAdapter] },
      appData: {},
      unobserve: jest.fn(),
    });
  };

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  beforeEach(() => {
    setActivePinia(createPinia());
  });

  afterEach(() => {
    jest.clearAllMocks();
    document.body.innerHTML = '';
  });

  it('starts with the server-rendered button', () => {
    mount();
    expect(get('serverButton')).not.toBeNull();
  });

  it('replaces the server-rendered button with a Vue CommitDiffsFileOptionsDropdown when the button is clicked', () => {
    mount();
    const button = get('serverButton');

    expect(get('vueButton')).toBeNull();
    expect(button).not.toBeNull();

    delegatedClick(button);

    expect(get('vueButton')).not.toBeNull();
    expect(get('serverButton')).toBeNull();
    expect(document.activeElement).toEqual(get('vueButton'));
  });

  it('renders the correct menu items in the dropdown as provided by the back end', () => {
    mount();
    const button = get('serverButton');

    delegatedClick(button);

    const items = Array.from(get('menuItems'));

    expect(items).toHaveLength(1);
    expect(items[0].textContent.trim()).toBe(item1.text);
    expect(items[0].querySelector('a').getAttribute('href')).toBe(item1.href);
  });
});
