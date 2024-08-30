/* eslint-disable no-param-reassign */

import $ from 'jquery';
import htmlDeprecatedJqueryDropdown from 'test_fixtures_static/deprecated_jquery_dropdown.html';
import mockProjects from 'test_fixtures_static/projects.json';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import '~/lib/utils/common_utils';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrl'),
}));

describe('deprecatedJQueryDropdown', () => {
  const NON_SELECTABLE_CLASSES =
    '.divider, .separator, .dropdown-header, .dropdown-menu-empty-item';
  const SEARCH_INPUT_SELECTOR = '.dropdown-input-field';
  const ITEM_SELECTOR = `.dropdown-content li:not(${NON_SELECTABLE_CLASSES})`;
  const FOCUSED_ITEM_SELECTOR = `${ITEM_SELECTOR} a.is-focused`;
  const ARROW_KEYS = {
    DOWN: 40,
    UP: 38,
    ENTER: 13,
    ESC: 27,
  };

  let remoteCallback;

  const test = {};

  // eslint-disable-next-line max-params
  const navigateWithKeys = (direction, steps, cb, i) => {
    i = i || 0;
    if (!i) direction = direction.toUpperCase();
    $('body').trigger({
      type: 'keydown',
      which: ARROW_KEYS[direction],
      keyCode: ARROW_KEYS[direction],
    });
    i += 1;
    if (i <= steps) {
      navigateWithKeys(direction, steps, cb, i);
    } else {
      cb();
    }
  };

  const remoteMock = (data, term, callback) => {
    remoteCallback = callback.bind({}, data);
  };

  function initDropDown(hasRemote, isFilterable, extraOpts = {}) {
    const options = {
      selectable: true,
      filterable: isFilterable,
      data: hasRemote ? remoteMock.bind({}, test.projectsData) : test.projectsData,
      search: {
        fields: ['name'],
      },
      text: (project) => project.name_with_namespace || project.name,
      id: (project) => project.id,
      ...extraOpts,
    };
    test.dropdownButtonElement = $('#js-project-dropdown', test.dropdownContainerElement);
    initDeprecatedJQueryDropdown(test.dropdownButtonElement, options);
  }

  beforeEach(() => {
    setHTMLFixture(htmlDeprecatedJqueryDropdown);
    test.dropdownContainerElement = $('.dropdown');
    test.$dropdownMenuElement = $('.dropdown-menu', test.dropdownContainerElement);
    test.projectsData = JSON.parse(JSON.stringify(mockProjects));
  });

  afterEach(() => {
    $('body').off('keydown');
    test.dropdownContainerElement.off('keyup');

    resetHTMLFixture();
  });

  it('should open on click', () => {
    initDropDown.call(this, false);

    expect(test.dropdownContainerElement).not.toHaveClass('show');
    test.dropdownButtonElement.click();

    expect(test.dropdownContainerElement).toHaveClass('show');
  });

  it('escapes HTML as text', () => {
    test.projectsData[0].name_with_namespace = '<script>alert("testing");</script>';

    initDropDown.call(this, false);

    test.dropdownButtonElement.click();

    expect($('.dropdown-content li:first-child').text()).toBe('<script>alert("testing");</script>');
  });

  it('should output HTML when highlighting', () => {
    test.projectsData[0].name_with_namespace = 'testing';
    $('.dropdown-input .dropdown-input-field').val('test');

    initDropDown.call(this, false, true, {
      highlight: true,
    });

    test.dropdownButtonElement.click();

    expect($('.dropdown-content li:first-child').text()).toBe('testing');

    expect($('.dropdown-content li:first-child a').html()).toBe(
      '<b>t</b><b>e</b><b>s</b><b>t</b>ing',
    );
  });

  describe('that is open', () => {
    beforeEach(() => {
      initDropDown.call(this, false, false);
      test.dropdownButtonElement.click();
    });

    it('should select a following item on DOWN keypress', () => {
      expect($(FOCUSED_ITEM_SELECTOR, test.$dropdownMenuElement).length).toBe(0);
      const randomIndex = Math.floor(Math.random() * (test.projectsData.length - 1)) + 0;
      navigateWithKeys('down', randomIndex, () => {
        expect($(FOCUSED_ITEM_SELECTOR, test.$dropdownMenuElement).length).toBe(1);
        expect($(`${ITEM_SELECTOR}:eq(${randomIndex}) a`, test.$dropdownMenuElement)).toHaveClass(
          'is-focused',
        );
      });
    });

    it('should select a previous item on UP keypress', () => {
      expect($(FOCUSED_ITEM_SELECTOR, test.$dropdownMenuElement).length).toBe(0);
      navigateWithKeys('down', test.projectsData.length - 1, () => {
        expect($(FOCUSED_ITEM_SELECTOR, test.$dropdownMenuElement).length).toBe(1);
        const randomIndex = Math.floor(Math.random() * (test.projectsData.length - 2)) + 0;
        navigateWithKeys('up', randomIndex, () => {
          expect($(FOCUSED_ITEM_SELECTOR, test.$dropdownMenuElement).length).toBe(1);
          expect(
            $(
              `${ITEM_SELECTOR}:eq(${test.projectsData.length - 2 - randomIndex}) a`,
              test.$dropdownMenuElement,
            ),
          ).toHaveClass('is-focused');
        });
      });
    });

    it('should click the selected item on ENTER keypress', () => {
      expect(test.dropdownContainerElement).toHaveClass('show');
      const randomIndex = Math.floor(Math.random() * (test.projectsData.length - 1)) + 0;
      navigateWithKeys('down', randomIndex, () => {
        navigateWithKeys('enter', null, () => {
          expect(test.dropdownContainerElement).not.toHaveClass('show');
          const link = $(`${ITEM_SELECTOR}:eq(${randomIndex}) a`, test.$dropdownMenuElement);

          expect(link).toHaveClass('is-active');
          const linkedLocation = link.attr('href');
          if (linkedLocation && linkedLocation !== '#') {
            expect(visitUrl).toHaveBeenCalledWith(linkedLocation);
          }
        });
      });
    });

    it('should close on ESC keypress', () => {
      expect(test.dropdownContainerElement).toHaveClass('show');
      test.dropdownContainerElement.trigger({
        type: 'keyup',
        which: ARROW_KEYS.ESC,
        keyCode: ARROW_KEYS.ESC,
      });

      expect(test.dropdownContainerElement).not.toHaveClass('show');
    });
  });

  describe('opened and waiting for a remote callback', () => {
    beforeEach(() => {
      initDropDown.call(this, true, true);
      test.dropdownButtonElement.click();
    });

    it('should show loading indicator while search results are being fetched by backend', () => {
      const dropdownMenu = document.querySelector('.dropdown-menu');

      expect(dropdownMenu.className.indexOf('is-loading')).not.toBe(-1);
      remoteCallback();

      expect(dropdownMenu.className.indexOf('is-loading')).toBe(-1);
    });

    it('should not focus search input while remote task is not complete', () => {
      expect(document.activeElement).toBeDefined();
      expect(document.activeElement).not.toEqual(document.querySelector(SEARCH_INPUT_SELECTOR));
      remoteCallback();

      expect(document.activeElement).toEqual(document.querySelector(SEARCH_INPUT_SELECTOR));
    });

    it('should focus search input after remote task is complete', () => {
      remoteCallback();

      expect(document.activeElement).toBeDefined();
      expect(document.activeElement).toEqual(document.querySelector(SEARCH_INPUT_SELECTOR));
    });

    it('should focus on input when opening for the second time after transition', () => {
      remoteCallback();
      test.dropdownContainerElement.trigger({
        type: 'keyup',
        which: ARROW_KEYS.ESC,
        keyCode: ARROW_KEYS.ESC,
      });
      test.dropdownButtonElement.click();
      test.dropdownContainerElement.trigger('transitionend');

      expect(document.activeElement).toBeDefined();
      expect(document.activeElement).toEqual(document.querySelector(SEARCH_INPUT_SELECTOR));
    });
  });

  describe('input focus with array data', () => {
    it('should focus input when passing array data to drop down', () => {
      initDropDown.call(this, false, true);
      test.dropdownButtonElement.click();
      test.dropdownContainerElement.trigger('transitionend');

      expect(document.activeElement).toBeDefined();
      expect(document.activeElement).toEqual(document.querySelector(SEARCH_INPUT_SELECTOR));
    });
  });

  it('should still have input value on close and restore', () => {
    const $searchInput = $(SEARCH_INPUT_SELECTOR);
    initDropDown.call(this, false, true);
    $searchInput.trigger('focus').val('g').trigger('input');

    expect($searchInput.val()).toEqual('g');
    test.dropdownButtonElement.trigger('hidden.bs.dropdown');
    $searchInput.trigger('blur').trigger('focus');

    expect($searchInput.val()).toEqual('g');
  });

  describe('renderItem', () => {
    function dropdownWithOptions(options) {
      const $dropdownDiv = $('<div />');

      initDeprecatedJQueryDropdown($dropdownDiv, options);

      return $dropdownDiv.data('deprecatedJQueryDropdown');
    }

    function basicDropdown() {
      return dropdownWithOptions({});
    }

    describe('without selected value', () => {
      let dropdown;

      beforeEach(() => {
        dropdown = basicDropdown();
      });

      it('marks items without ID as active', () => {
        const dummyData = {};

        const html = dropdown.renderItem(dummyData, null, null);

        const link = html.querySelector('a');

        expect(link).toHaveClass('is-active');
      });

      it('does not mark items with ID as active', () => {
        const dummyData = {
          id: 'ea',
        };

        const html = dropdown.renderItem(dummyData, null, null);

        const link = html.querySelector('a');

        expect(link).not.toHaveClass('is-active');
      });
    });

    it('should return an empty .separator li when when appropriate', () => {
      const dropdown = basicDropdown();
      const sep = { type: 'separator' };
      const li = dropdown.renderItem(sep);

      expect(li).toHaveClass('separator');
      expect(li.childNodes.length).toEqual(0);
    });

    it('should return an empty .divider li when when appropriate', () => {
      const dropdown = basicDropdown();
      const div = { type: 'divider' };
      const li = dropdown.renderItem(div);

      expect(li).toHaveClass('divider');
      expect(li.childNodes.length).toEqual(0);
    });

    it('should return a .dropdown-header li with the correct content when when appropriate', () => {
      const dropdown = basicDropdown();
      const text = 'My Header';
      const header = { type: 'header', content: text };
      const li = dropdown.renderItem(header);

      expect(li).toHaveClass('dropdown-header');
      expect(li.childNodes.length).toEqual(1);
      expect(li.textContent).toEqual(text);
    });

    describe('with a trackSuggestionsClickedLabel', () => {
      it('includes data-track attributes', () => {
        const dropdown = dropdownWithOptions({
          trackSuggestionClickedLabel: 'some_value_for_label',
        });
        const item = {
          id: 'some-element-id',
          text: 'the link text',
          url: 'http://example.com',
          category: 'Suggestion category',
        };
        const li = dropdown.renderItem(item, null, 3);
        const link = li.querySelector('a');

        expect(link).toHaveAttr('data-track-action', 'click_text');
        expect(link).toHaveAttr('data-track-label', 'some_value_for_label');
        expect(link).toHaveAttr('data-track-value', '3');
        expect(link).toHaveAttr('data-track-property', 'suggestion-category');
      });

      it('defaults property to no_category when category not provided', () => {
        const dropdown = dropdownWithOptions({
          trackSuggestionClickedLabel: 'some_value_for_label',
        });
        const item = {
          id: 'some-element-id',
          text: 'the link text',
          url: 'http://example.com',
        };
        const li = dropdown.renderItem(item);
        const link = li.querySelector('a');

        expect(link).toHaveAttr('data-track-property', 'no-category');
      });
    });
  });

  it('should keep selected item after selecting a second time', () => {
    const options = {
      isSelectable(item, $el) {
        return !$el.hasClass('is-active');
      },
      toggleLabel(item) {
        return item && item.id;
      },
    };
    initDropDown.call(this, false, false, options);
    const $item = $(`${ITEM_SELECTOR}:first() a`, test.$dropdownMenuElement);

    // select item the first time
    test.dropdownButtonElement.click();
    $item.click();

    expect($item).toHaveClass('is-active');
    // select item the second time
    test.dropdownButtonElement.click();
    $item.click();

    expect($item).toHaveClass('is-active');

    expect($('.dropdown-toggle-text')).toHaveText(test.projectsData[0].id.toString());
  });
});
