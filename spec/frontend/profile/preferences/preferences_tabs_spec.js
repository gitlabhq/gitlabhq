import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import setWindowLocation from 'helpers/set_window_location_helper';
import { initPreferencesTabs } from '~/profile/preferences/preferences_tabs';
import { ACTIVE_PANEL_CLASS } from '~/tabs/constants';
import { HIDE_CLASS, SEARCH_TERM_CHANGED_EVENT } from '~/search_settings/constants';

describe('initPreferencesTabs', () => {
  const findTabs = () => document.querySelector('.js-preferences-tabs');
  const findTabsWrapper = () => document.querySelector('.gl-tabs-wrapper');
  const findForm = () => document.querySelector('form');
  const findTab = (id) => document.querySelector(`a[href="#${id}"]`);
  const findPane = (id) => document.getElementById(`${id}-pane`);
  const isActive = (id) => findPane(id).classList.contains(ACTIVE_PANEL_CLASS);

  const dispatchSearch = (searchTerm) => {
    document.body.dispatchEvent(
      new CustomEvent(SEARCH_TERM_CHANGED_EVENT, { bubbles: true, detail: { searchTerm } }),
    );
  };

  beforeEach(() => {
    setWindowLocation('/-/profile/preferences');
    setHTMLFixture(`
      <form>
        <div class="gl-tabs-wrapper">
          <ul class="nav gl-tabs-nav js-preferences-tabs">
            <li class="nav-item"><a href="#appearance" aria-controls="appearance-pane" class="gl-tab-nav-item active">Appearance</a></li>
            <li class="nav-item"><a href="#editing" aria-controls="editing-pane" class="gl-tab-nav-item">Editing</a></li>
          </ul>
        </div>
        <div class="tab-content">
          <div id="appearance-pane" class="tab-pane active"></div>
          <div id="editing-pane" class="tab-pane">
            <input id="user_tab_width" name="user[tab_width]" type="number" min="1" required />
          </div>
        </div>
      </form>
    `);

    initPreferencesTabs({ tabsEl: findTabs(), formEl: findForm() });
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('activates the tab containing a field that fails validation', () => {
    findPane('editing').querySelector('input').dispatchEvent(new Event('invalid'));

    expect(isActive('editing')).toBe(true);
    expect(isActive('appearance')).toBe(false);
  });

  describe('settings search', () => {
    it('shows every pane and hides the tabs while a search term is active', () => {
      dispatchSearch('tab');

      expect(isActive('appearance')).toBe(true);
      expect(isActive('editing')).toBe(true);
      expect(findTabsWrapper()).toHaveClass(HIDE_CLASS);
    });

    it('restores the active tab when the search term is cleared', () => {
      findTab('editing').click();
      dispatchSearch('tab');
      dispatchSearch('');

      expect(isActive('editing')).toBe(true);
      expect(isActive('appearance')).toBe(false);
      expect(findTabsWrapper()).not.toHaveClass(HIDE_CLASS);
    });
  });
});
