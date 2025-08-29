import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import TableContents from '~/blob/components/table_contents.vue';

let wrapper;

const MARKDOWN_FIXTURE = `
  <div class="blob-viewer" data-type="rich" data-loaded="false">
    <h1><a id="hello">$</a> Hello</h1>
    <h2><a id="world">$</a> World</h2>
    <h3><a id="hakuna">$</a> Hakuna</h3>
    <h2><a id="matata">$</a> Matata</h2>
  </div>
`;

const MARKDOWN_FIXTURE_WITHOUT_ANCHORS = `
  <div class="blob-viewer" data-type="rich" data-loaded="false">
    <h1>Title Without Anchor</h1>
    <h2><a id="world">$</a> World</h2>
    <h3><a id="hakuna">$</a> Hakuna</h3>
    <h2><a id="matata">$</a> Matata</h2>
  </div>
`;

const ASCIIDOC_FIXTURE = `
  <div class="blob-viewer" data-type="rich" data-loaded="false">
    <h1 id="user-content-introduction">
      <a class="anchor" href="#user-content-introduction"></a>
      Introduction
    </h1>
    <h2 id="user-content-first-section">
      <a class="anchor" href="#user-content-first-section"></a>
      First section
    </h2>
    <h3 id="user-content-subsection">
      <a class="anchor" href="#user-content-subsection"></a>
      Subsection
    </h3>
    <h2 id="user-content-second-section">
      <a class="anchor" href="#user-content-second-section"></a>
      Second section
    </h2>
  </div>
`;

const ASCIIDOC_FIXTURE_WITHOUT_ANCHORS = `
  <div class="blob-viewer" data-type="rich" data-loaded="false">
    <h1 id="user-content-title">Title Without Anchor</h1>
    <h2 id="user-content-first-section">
      <a class="anchor" href="#user-content-first-section"></a>
      First section
    </h2>
    <h3 id="user-content-subsection">
      <a class="anchor" href="#user-content-subsection"></a>
      Subsection
    </h3>
  </div>
`;

function createComponent() {
  wrapper = shallowMount(TableContents);
}

const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
const findDropdownItems = () => findDropdown().props('items');

async function setLoaded(loaded) {
  document.querySelector('.blob-viewer').dataset.loaded = loaded;

  await nextTick();
}

describe('Markdown table of contents component', () => {
  beforeEach(() => {
    setHTMLFixture(MARKDOWN_FIXTURE);
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

      expect(findDropdown().exists()).toBe(true);
      expect(findDropdown().props('items')).toHaveLength(4);

      // make sure that this only happens once
      await setLoaded(true);

      expect(findDropdown().props('items')).toHaveLength(4);
    });

    it('generates proper anchor links (uses anchor id)', async () => {
      createComponent();
      await setLoaded(true);

      const hrefs = findDropdownItems().map((item) => item.href);
      expect(hrefs).toEqual(['#hello', '#world', '#hakuna', '#matata']);
    });

    it('sets padding for dropdown items', async () => {
      createComponent();

      await setLoaded(true);

      expect(findDropdownItems()[0].extraAttrs.style.paddingLeft).toBe('16px');
      expect(findDropdownItems()[1].extraAttrs.style.paddingLeft).toBe('24px');
      expect(findDropdownItems()[2].extraAttrs.style.paddingLeft).toBe('32px');
      expect(findDropdownItems()[3].extraAttrs.style.paddingLeft).toBe('24px');
    });

    it('excludes headings without nested anchor elements', async () => {
      resetHTMLFixture();
      setHTMLFixture(MARKDOWN_FIXTURE_WITHOUT_ANCHORS);

      createComponent();
      await setLoaded(true);

      expect(findDropdown().exists()).toBe(true);
      expect(findDropdownItems()).toHaveLength(3);

      const hrefs = findDropdownItems().map((item) => item.href);
      expect(hrefs).toEqual(['#world', '#hakuna', '#matata']);

      const texts = findDropdownItems().map((item) => item.text);
      expect(texts).toEqual(['$ World', '$ Hakuna', '$ Matata']);
      expect(texts).not.toContain('Title Without Anchor');
    });
  });
});

describe('AsciiDoc table of contents component', () => {
  beforeEach(() => {
    setHTMLFixture(ASCIIDOC_FIXTURE);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('loaded', () => {
    it('populates dropdown with AsciiDoc content', async () => {
      createComponent();
      await setLoaded(true);

      expect(findDropdown().exists()).toBe(true);
      expect(findDropdownItems()).toHaveLength(4);
    });

    it('generates proper anchor links for AsciiDoc (uses anchor href)', async () => {
      createComponent();
      await setLoaded(true);

      const hrefs = findDropdownItems().map((item) => item.href);

      expect(hrefs).toEqual([
        '#user-content-introduction',
        '#user-content-first-section',
        '#user-content-subsection',
        '#user-content-second-section',
      ]);
    });

    it('extracts correct text content for AsciiDoc headings', async () => {
      createComponent();
      await setLoaded(true);

      const texts = findDropdownItems().map((item) => item.text);

      expect(texts).toEqual(['Introduction', 'First section', 'Subsection', 'Second section']);
    });

    it('excludes AsciiDoc headings without nested anchor elements', async () => {
      resetHTMLFixture();
      setHTMLFixture(ASCIIDOC_FIXTURE_WITHOUT_ANCHORS);

      createComponent();
      await setLoaded(true);

      expect(findDropdown().exists()).toBe(true);
      expect(findDropdownItems()).toHaveLength(2);

      const hrefs = findDropdownItems().map((item) => item.href);
      expect(hrefs).toEqual(['#user-content-first-section', '#user-content-subsection']);

      const texts = findDropdownItems().map((item) => item.text);
      expect(texts).toEqual(['First section', 'Subsection']);
      expect(texts).not.toContain('Title Without Anchor');
    });
  });
});
