import { GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SearchSettings from '~/search_settings/components/search_settings.vue';
import { HIGHLIGHT_CLASS, HIDE_CLASS } from '~/search_settings/constants';

describe('search_settings/components/search_settings.vue', () => {
  const ROOT_ID = 'content-body';
  const SECTION_SELECTOR = 'section.settings';
  const SEARCH_TERM = 'Delete project';
  const GENERAL_SETTINGS_ID = 'js-general-settings';
  const ADVANCED_SETTINGS_ID = 'js-advanced-settings';
  let wrapper;

  const buildWrapper = () => {
    wrapper = shallowMount(SearchSettings, {
      propsData: {
        searchRoot: document.querySelector(`#${ROOT_ID}`),
        sectionSelector: SECTION_SELECTOR,
      },
    });
  };

  const sections = () => Array.from(document.querySelectorAll(SECTION_SELECTOR));
  const sectionsCount = () => sections().length;
  const visibleSectionsCount = () =>
    document.querySelectorAll(`${SECTION_SELECTOR}:not(.${HIDE_CLASS})`).length;
  const highlightedElementsCount = () => document.querySelectorAll(`.${HIGHLIGHT_CLASS}`).length;
  const findSearchBox = () => wrapper.find(GlSearchBoxByType);
  const search = (term) => {
    findSearchBox().vm.$emit('input', term);
  };
  const clearSearch = () => search('');

  beforeEach(() => {
    setFixtures(`
    <div>
      <div class="js-search-app"></div>
      <div id="${ROOT_ID}">
        <section id="${GENERAL_SETTINGS_ID}" class="settings">
          <span>General</span>
        </section>
        <section id="${ADVANCED_SETTINGS_ID}" class="settings">
          <span>${SEARCH_TERM}</span>
        </section>
      </div>
    </div>
    `);
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('expands first section and collapses the rest', () => {
    clearSearch();

    const [firstSection, ...otherSections] = sections();

    expect(wrapper.emitted()).toEqual({
      expand: [[firstSection]],
      collapse: otherSections.map((x) => [x]),
    });
  });

  it('hides sections that do not match the search term', () => {
    const hiddenSection = document.querySelector(`#${GENERAL_SETTINGS_ID}`);
    search(SEARCH_TERM);

    expect(visibleSectionsCount()).toBe(1);
    expect(hiddenSection.classList).toContain(HIDE_CLASS);
  });

  it('expands section that matches the search term', () => {
    const section = document.querySelector(`#${ADVANCED_SETTINGS_ID}`);

    search(SEARCH_TERM);

    // Last called because expand is always called once to reset the page state
    expect(wrapper.emitted().expand[1][0]).toBe(section);
  });

  it('highlight elements that match the search term', () => {
    search(SEARCH_TERM);

    expect(highlightedElementsCount()).toBe(1);
  });

  describe('when search term is cleared', () => {
    beforeEach(() => {
      search(SEARCH_TERM);
    });

    it('displays all sections', () => {
      expect(visibleSectionsCount()).toBe(1);
      clearSearch();
      expect(visibleSectionsCount()).toBe(sectionsCount());
    });

    it('removes the highlight from all elements', () => {
      expect(highlightedElementsCount()).toBe(1);
      clearSearch();
      expect(highlightedElementsCount()).toBe(0);
    });
  });
});
