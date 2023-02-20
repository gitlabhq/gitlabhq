import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import FilteredSearchDropdownManager from '~/filtered_search/filtered_search_dropdown_manager';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('Filtered Search Dropdown Manager', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet().reply(HTTP_STATUS_OK);
  });

  describe('addWordToInput', () => {
    function getInputValue() {
      return document.querySelector('.filtered-search').value;
    }

    function setInputValue(value) {
      document.querySelector('.filtered-search').value = value;
    }

    beforeEach(() => {
      setHTMLFixture(`
        <ul class="tokens-container">
          <li class="input-token">
            <input class="filtered-search">
          </li>
        </ul>
      `);
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    describe('input has no existing value', () => {
      it('should add just tokenName', () => {
        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'milestone' });

        const token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').textContent).toBe('milestone');
        expect(getInputValue()).toBe('');
      });

      it('should add tokenName, tokenOperator, and tokenValue', () => {
        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'label' });

        let token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').textContent).toBe('label');
        expect(getInputValue()).toBe('');

        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'label', tokenOperator: '=' });

        token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').textContent).toBe('label');
        expect(token.querySelector('.operator').textContent).toBe('=');
        expect(getInputValue()).toBe('');

        FilteredSearchDropdownManager.addWordToInput({
          tokenName: 'label',
          tokenOperator: '=',
          tokenValue: 'none',
        });
        // We have to get that reference again
        // Because FilteredSearchDropdownManager deletes the previous token
        token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').textContent).toBe('label');
        expect(token.querySelector('.operator').textContent).toBe('=');
        expect(token.querySelector('.value').textContent).toBe('none');
        expect(getInputValue()).toBe('');
      });
    });

    describe('input has existing value', () => {
      it('should be able to just add tokenName', () => {
        setInputValue('a');
        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'author' });

        const token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').textContent).toBe('author');
        expect(getInputValue()).toBe('');
      });

      it('should replace tokenValue', () => {
        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'author' });
        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'author', tokenOperator: '=' });

        setInputValue('roo');
        FilteredSearchDropdownManager.addWordToInput({
          tokenName: null,
          tokenOperator: '=',
          tokenValue: '@root',
        });

        const token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').textContent).toBe('author');
        expect(token.querySelector('.operator').textContent).toBe('=');
        expect(token.querySelector('.value').textContent).toBe('@root');
        expect(getInputValue()).toBe('');
      });

      it('should add tokenValues containing spaces', () => {
        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'label' });

        setInputValue('"test ');
        FilteredSearchDropdownManager.addWordToInput({
          tokenName: 'label',
          tokenOperator: '=',
          tokenValue: '~\'"test me"\'',
        });

        const token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').textContent).toBe('label');
        expect(token.querySelector('.operator').textContent).toBe('=');
        expect(token.querySelector('.value').textContent).toBe('~\'"test me"\'');
        expect(getInputValue()).toBe('');
      });
    });
  });
});
