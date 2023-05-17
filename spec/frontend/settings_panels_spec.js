import $ from 'jquery';
import htmlGroupsEdit from 'test_fixtures/groups/edit.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initSettingsPanels, { isExpanded } from '~/settings_panels';

describe('Settings Panels', () => {
  beforeEach(() => {
    setHTMLFixture(htmlGroupsEdit);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('initSettingsPane', () => {
    afterEach(() => {
      window.location.hash = '';
    });

    it('should expand linked hash fragment panel', () => {
      window.location.hash = '#js-general-settings';

      const panel = document.querySelector('#js-general-settings');
      // Our test environment automatically expands everything so we need to clear that out first
      panel.classList.remove('expanded');

      expect(isExpanded(panel)).toBe(false);

      initSettingsPanels();

      expect(isExpanded(panel)).toBe(true);
    });

    it('should expand panel containing linked hash', () => {
      window.location.hash = '#group_description';

      const panel = document.querySelector('#js-general-settings');
      // Our test environment automatically expands everything so we need to clear that out first
      panel.classList.remove('expanded');

      expect(isExpanded(panel)).toBe(false);

      initSettingsPanels();

      expect(isExpanded(panel)).toBe(true);
    });
  });

  it('does not change the text content of triggers', () => {
    const panel = document.querySelector('#js-general-settings');
    const trigger = panel.querySelector('.js-settings-toggle-trigger-only');
    const originalText = trigger.textContent;

    initSettingsPanels();

    expect(isExpanded(panel)).toBe(true);

    $(trigger).click();

    expect(isExpanded(panel)).toBe(false);
    expect(trigger.textContent).toEqual(originalText);
  });
});
