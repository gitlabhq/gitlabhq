import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import TableContents from '~/blob/components/table_contents.vue';

let wrapper;

function createComponent() {
  wrapper = shallowMount(TableContents);
}

const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

async function setLoaded(loaded) {
  document.querySelector('.blob-viewer').dataset.loaded = loaded;

  await nextTick();
}

describe('Markdown table of contents component', () => {
  beforeEach(() => {
    setHTMLFixture(`
      <div class="blob-viewer" data-type="rich" data-loaded="false">
        <h1><a id="hello">$</a> Hello</h1>
        <h2><a id="world">$</a> World</h2>
        <h3><a id="hakuna">$</a> Hakuna</h3>
        <h2><a id="matata">$</a> Matata</h2>
      </div>
    `);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('not loaded', () => {
    it('does not populate dropdown', () => {
      createComponent();

      expect(findDropdown().exists()).toBe(false);
    });

    it('does not show dropdown when loading blob content', async () => {
      createComponent();

      await setLoaded(false);

      expect(findDropdown().exists()).toBe(false);
    });

    it('does not show dropdown when viewing non-rich content', async () => {
      createComponent();

      document.querySelector('.blob-viewer').dataset.type = 'simple';

      await setLoaded(true);

      expect(findDropdown().exists()).toBe(false);
    });
  });

  describe('loaded', () => {
    it('populates dropdown', async () => {
      createComponent();

      await setLoaded(true);

      const dropdown = findDropdown();

      expect(dropdown.exists()).toBe(true);
      expect(dropdown.props('items').length).toBe(4);

      // make sure that this only happens once
      await setLoaded(true);

      expect(dropdown.props('items').length).toBe(4);
    });

    it('generates proper anchor links', async () => {
      createComponent();
      await setLoaded(true);

      const dropdown = findDropdown();
      const items = dropdown.props('items');
      const hrefs = items.map((item) => item.href);
      expect(hrefs).toEqual(['#hello', '#world', '#hakuna', '#matata']);
    });

    it('sets padding for dropdown items', async () => {
      createComponent();

      await setLoaded(true);

      const items = findDropdown().props('items');

      expect(items[0].extraAttrs.style.paddingLeft).toBe('16px');
      expect(items[1].extraAttrs.style.paddingLeft).toBe('24px');
      expect(items[2].extraAttrs.style.paddingLeft).toBe('32px');
      expect(items[3].extraAttrs.style.paddingLeft).toBe('24px');
    });
  });
});
