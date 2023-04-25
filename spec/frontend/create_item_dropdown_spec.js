import $ from 'jquery';
import htmlCreateItemDropdown from 'test_fixtures_static/create_item_dropdown.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import CreateItemDropdown from '~/create_item_dropdown';

const DROPDOWN_ITEM_DATA = [
  {
    title: 'one',
    id: 'one',
    text: 'one',
  },
  {
    title: 'two',
    id: 'two',
    text: 'two',
  },
  {
    title: 'three',
    id: 'three',
    text: 'three',
  },
  {
    title: '<b>four</b>title',
    id: '<b>four</b>id',
    text: '<b>four</b>text',
  },
];

describe('CreateItemDropdown', () => {
  let $wrapperEl;
  let createItemDropdown;

  function createItemAndClearInput(text) {
    // Filter for the new item
    $wrapperEl.find('.dropdown-input-field').val(text).trigger('input');

    // Create the new item
    const $createButton = $wrapperEl.find('.js-dropdown-create-new-item');
    $createButton.click();

    // Clear out the filter
    $wrapperEl.find('.dropdown-input-field').val('').trigger('input');
  }

  beforeEach(() => {
    setHTMLFixture(htmlCreateItemDropdown);
    $wrapperEl = $('.js-create-item-dropdown-fixture-root');
  });

  afterEach(() => {
    $wrapperEl.remove();
    resetHTMLFixture();
  });

  describe('items', () => {
    beforeEach(() => {
      createItemDropdown = new CreateItemDropdown({
        $dropdown: $wrapperEl.find('.js-dropdown-menu-toggle'),
        defaultToggleLabel: 'All variables',
        fieldName: 'variable[environment]',
        getData: (term, callback) => {
          callback(DROPDOWN_ITEM_DATA);
        },
      });
    });

    it('should have a dropdown item for each piece of data', () => {
      // Get the data in the dropdown
      $('.js-dropdown-menu-toggle').click();

      const $itemEls = $wrapperEl.find('.js-dropdown-content a');

      expect($itemEls.length).toEqual(DROPDOWN_ITEM_DATA.length);

      DROPDOWN_ITEM_DATA.forEach((dataItem, i) => {
        expect($($itemEls[i]).text()).toEqual(dataItem.text);
      });
    });
  });

  describe('created items', () => {
    const NEW_ITEM_TEXT = 'foobarbaz';

    beforeEach(() => {
      createItemDropdown = new CreateItemDropdown({
        $dropdown: $wrapperEl.find('.js-dropdown-menu-toggle'),
        defaultToggleLabel: 'All variables',
        fieldName: 'variable[environment]',
        getData: (term, callback) => {
          callback(DROPDOWN_ITEM_DATA);
        },
      });

      // Open the dropdown
      $('.js-dropdown-menu-toggle').click();

      // Filter for the new item
      $wrapperEl.find('.dropdown-input-field').val(NEW_ITEM_TEXT).trigger('input');
    });

    it('create new item button should include the filter text', () => {
      expect($wrapperEl.find('.js-dropdown-create-new-item code').text()).toEqual(NEW_ITEM_TEXT);
    });

    it('should update the dropdown with the newly created item', () => {
      // Create the new item
      const $createButton = $wrapperEl.find('.js-dropdown-create-new-item');
      $createButton.click();

      expect($wrapperEl.find('.dropdown-toggle-text').text()).toEqual(NEW_ITEM_TEXT);
      expect($wrapperEl.find('input[name="variable[environment]"]').val()).toEqual(NEW_ITEM_TEXT);
    });

    it('should include newly created item in dropdown list', () => {
      createItemAndClearInput(NEW_ITEM_TEXT);

      const $itemEls = $wrapperEl.find('.js-dropdown-content a');

      expect($itemEls.length).toEqual(1 + DROPDOWN_ITEM_DATA.length);
      expect($($itemEls.get(DROPDOWN_ITEM_DATA.length)).text()).toEqual(NEW_ITEM_TEXT);
    });

    it('should not duplicate an item when trying to create an existing item', () => {
      createItemAndClearInput(DROPDOWN_ITEM_DATA[0].text);

      const $itemEls = $wrapperEl.find('.js-dropdown-content a');

      expect($itemEls.length).toEqual(DROPDOWN_ITEM_DATA.length);
    });
  });

  describe('clearDropdown()', () => {
    beforeEach(() => {
      createItemDropdown = new CreateItemDropdown({
        $dropdown: $wrapperEl.find('.js-dropdown-menu-toggle'),
        defaultToggleLabel: 'All variables',
        fieldName: 'variable[environment]',
        getData: (term, callback) => {
          callback(DROPDOWN_ITEM_DATA);
        },
      });
    });

    it('should clear all data and filter input', () => {
      const filterInput = $wrapperEl.find('.dropdown-input-field');

      // Get the data in the dropdown
      $('.js-dropdown-menu-toggle').click();

      // Filter for an item
      filterInput.val('one').trigger('input');

      const $itemElsAfterFilter = $wrapperEl.find('.js-dropdown-content a');

      expect($itemElsAfterFilter.length).toEqual(1);

      createItemDropdown.clearDropdown();

      const $itemElsAfterClear = $wrapperEl.find('.js-dropdown-content a');

      expect($itemElsAfterClear.length).toEqual(0);
      expect(filterInput.val()).toEqual('');
    });
  });

  describe('createNewItemFromValue option', () => {
    beforeEach(() => {
      createItemDropdown = new CreateItemDropdown({
        $dropdown: $wrapperEl.find('.js-dropdown-menu-toggle'),
        defaultToggleLabel: 'All variables',
        fieldName: 'variable[environment]',
        getData: (term, callback) => {
          callback(DROPDOWN_ITEM_DATA);
        },
        createNewItemFromValue: (newValue) => ({
          title: `${newValue}-title`,
          id: `${newValue}-id`,
          text: `${newValue}-text`,
        }),
      });
    });

    it('all items go through createNewItemFromValue', () => {
      // Get the data in the dropdown
      $('.js-dropdown-menu-toggle').click();

      createItemAndClearInput('new-item');

      const $itemEls = $wrapperEl.find('.js-dropdown-content a');

      expect($itemEls.length).toEqual(1 + DROPDOWN_ITEM_DATA.length);
      expect($($itemEls[DROPDOWN_ITEM_DATA.length]).text()).toEqual('new-item-text');
      expect($wrapperEl.find('.dropdown-toggle-text').text()).toEqual('new-item-title');
    });
  });
});
