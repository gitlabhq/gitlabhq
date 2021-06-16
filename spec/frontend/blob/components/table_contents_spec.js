import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import TableContents from '~/blob/components/table_contents.vue';

let wrapper;

function createComponent() {
  wrapper = shallowMount(TableContents);
}

async function setLoaded(loaded) {
  document.querySelector('.blob-viewer').setAttribute('data-loaded', loaded);

  await nextTick();
}

describe('Markdown table of contents component', () => {
  beforeEach(() => {
    setFixtures(`
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
  });

  describe('not loaded', () => {
    it('does not populate dropdown', () => {
      createComponent();

      expect(wrapper.findComponent(GlDropdownItem).exists()).toBe(false);
    });
  });

  describe('loaded', () => {
    it('populates dropdown', async () => {
      createComponent();

      await setLoaded(true);

      const dropdownItems = wrapper.findAllComponents(GlDropdownItem);

      expect(dropdownItems.exists()).toBe(true);
      expect(dropdownItems.length).toBe(4);
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
