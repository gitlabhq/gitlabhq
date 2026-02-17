import { nextTick } from 'vue';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { optionsMenuAdapter } from '~/rapid_diffs/adapters/options_menu';

describe('Diff File Options Menu Adapter', () => {
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

  const mount = () => {
    const viewer = 'any';
    const oldPath = '/old';
    const newPath = '/new';
    document.body.innerHTML = `
      <diff-file id="file" data-file-data='${JSON.stringify({ viewer, old_path: oldPath, new_path: newPath })}'>
        <div class="rd-diff-file">
          <div class="rd-diff-file-header">
          <div class="rd-diff-file-options-menu">
            <div data-options-menu>
              <script type="application/json">
                [{"text": "${item1.text}", "href": "${item1.href}"}]
              </script>
              <button data-click="toggleOptionsMenu" type="button"></button>
            </div>
          </div>
          <div></div>
        </div>
      </diff-file>
    `;
    get('file').mount({
      adapterConfig: { [viewer]: [optionsMenuAdapter] },
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

  it('replaces the server-rendered button with a Vue GlDisclosureDropdown when the button is clicked', async () => {
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
    // Wait for Vue 3 to complete child component rendering and focus
    await nextTick();
    expect(document.activeElement).toEqual(get('vueButton'));
  });

  it('renders the correct menu items in the GlDisclosureDropdown as provided by the back end', () => {
    const button = get('serverButton');

    delegatedClick(button);

    const items = Array.from(get('menuItems'));

    expect(items[0].textContent.trim()).toBe('Copy link to the file');
    expect(items[1].textContent.trim()).toBe(item1.text);
    expect(items[1].querySelector('a').getAttribute('href')).toBe(item1.href);
  });
});
