import $ from 'jquery';
import htmlGroupsEdit from 'test_fixtures/groups/edit.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initSettingsPanels, { isExpanded, toggleSection } from '~/settings_panels';

const pushStateSpy = jest.fn();

describe('Settings Panels', () => {
  beforeEach(() => {
    setHTMLFixture(htmlGroupsEdit);

    // Mock history and location APIs
    window.history.pushState = pushStateSpy;
    Object.defineProperty(window, 'location', {
      value: {
        hash: '',
        pathname: '/settings',
        search: '?param=1',
      },
      writable: true,
    });
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

  describe('toggleSection', () => {
    let $section;

    beforeEach(() => {
      $section = $('#js-general-settings');
    });

    it('removes no-animate class when toggling', () => {
      $section.addClass('no-animate');
      toggleSection($section);
      expect($section.hasClass('no-animate')).toBe(false);
    });

    describe('when section is not expanded', () => {
      beforeEach(() => {
        $section.removeClass('expanded');
      });

      it('expands the section', () => {
        toggleSection($section);
        expect(isExpanded($section[0])).toBe(true);
      });

      it('adds section ID to URL hash', () => {
        toggleSection($section);
        expect(window.location.hash).toBe('js-general-settings');
      });
    });

    describe('when section is expanded', () => {
      beforeEach(() => {
        $section.addClass('expanded');
      });

      it('closes the section', () => {
        toggleSection($section);
        expect(isExpanded($section[0])).toBe(false);
      });

      it('removes hash from URL', () => {
        toggleSection($section);
        expect(pushStateSpy).toHaveBeenCalledWith('', document.title, '/settings?param=1');
      });
    });
  });
});
