import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import TableContents from '~/blob/components/table_contents.vue';

let wrapper;

function createComponent() {
  wrapper = shallowMount(TableContents);
}

async function setLoaded(loaded) {
  document.querySelector('.blob-viewer').dataset.loaded = loaded;

  await nextTick();
}

describe('Markdown table of contents component', () => {
  beforeEach(() => {
    setHTMLFixture(`
      <div class="blob-viewer" data-type="rich" data-loaded="false">
        <h1><a href="#1"></a>Hello</h1>
        <h2><a href="#2"></a>World</h2>
        <h3><a href="#3"></a>Testing</h3>
        <h2><a href="#4"></a>GitLab</h2>
      </div>
    `);
  });

  afterEach(() => {
    wrapper.destroy();
    resetHTMLFixture();
  });

  describe('not loaded', () => {
    const findDropdownItem = () => wrapper.findComponent(GlDropdownItem);

    it('does not populate dropdown', () => {
      createComponent();

      expect(findDropdownItem().exists()).toBe(false);
    });

    it('does not show dropdown when loading blob content', async () => {
      createComponent();

      await setLoaded(false);

      expect(findDropdownItem().exists()).toBe(false);
    });

    it('does not show dropdown when viewing non-rich content', async () => {
      createComponent();

      document.querySelector('.blob-viewer').dataset.type = 'simple';

      await setLoaded(true);

      expect(findDropdownItem().exists()).toBe(false);
    });
  });

  describe('loaded', () => {
    it('populates dropdown', async () => {
      createComponent();

      await setLoaded(true);

      const dropdownItems = wrapper.findAllComponents(GlDropdownItem);

      expect(dropdownItems.exists()).toBe(true);
      expect(dropdownItems.length).toBe(4);

      // make sure that this only happens once
      await setLoaded(true);

      expect(wrapper.findAllComponents(GlDropdownItem).length).toBe(4);
    });

    it('sets padding for dropdown items', async () => {
      createComponent();

      await setLoaded(true);

      const dropdownLinks = wrapper.findAll('[data-testid="tableContentsLink"]');

      expect(dropdownLinks.at(0).element.style.paddingLeft).toBe('0px');
      expect(dropdownLinks.at(1).element.style.paddingLeft).toBe('8px');
      expect(dropdownLinks.at(2).element.style.paddingLeft).toBe('16px');
      expect(dropdownLinks.at(3).element.style.paddingLeft).toBe('8px');
    });
  });
});
