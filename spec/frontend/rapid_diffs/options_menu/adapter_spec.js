import { DiffFile } from '~/rapid_diffs/diff_file';
import { OptionsMenuAdapter } from '~/rapid_diffs/options_menu/adapter';

describe('Diff File Options Menu', () => {
  const item1 = { text: 'item 1', path: 'item/1/path' };

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

  const mount = () => {
    const viewer = 'any';
    document.body.innerHTML = `
      <diff-file data-file-data='${JSON.stringify({ viewer })}'>
        <div class="rd-diff-file">
          <div class="rd-diff-file-header" data-testid="rd-diff-file-header">
          <div class="rd-diff-file-options-menu gl-ml-2">
            <div data-options-menu>
              <script type="application/json">
                [{"text": "${item1.text}", "href": "${item1.path}"}]
              </script>
              <button data-click="toggleOptionsMenu" type="button"></button>
            </div>
          </div>
          <div data-file-body=""><!-- body content --></div>
        </div>
      </diff-file>
    `;
    get('file').mount({
      adapterConfig: { [viewer]: [OptionsMenuAdapter] },
      appData: {},
      unobserve: jest.fn(),
    });
  };

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  beforeEach(() => {
    mount();
  });

  it('starts with the server-rendered button', () => {
    expect(get('serverButton')).not.toBeNull();
  });

  it('replaces the server-rendered button with a Vue GlDisclosureDropdown when the button is clicked', () => {
    const button = get('serverButton');

    expect(get('vueButton')).toBeNull();
    expect(button).not.toBeNull();

    delegatedClick(button);

    expect(get('vueButton')).not.toBeNull();
    /*
     * This button being replaced also means this replacement can only
     * happen once (desireable!), so testing that it's no longer present is good
     */
    expect(get('serverButton')).toBeNull();
    expect(document.activeElement).toEqual(get('vueButton'));
  });

  it('renders the correct menu items in the GlDisclosureDropdown as provided by the back end', () => {
    const button = get('serverButton');

    delegatedClick(button);

    const items = Array.from(get('menuItems'));

    expect(items).toHaveLength(1);
    expect(items[0].textContent.trim()).toBe(item1.text);
    expect(items[0].querySelector('a').getAttribute('href')).toBe(item1.path);
  });
});
