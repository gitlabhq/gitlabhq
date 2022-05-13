import $ from 'jquery';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import '~/commons/bootstrap';

describe('Bootstrap jQuery extensions', () => {
  describe('disable', () => {
    beforeEach(() => {
      setHTMLFixture('<input type="text" />');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('adds the disabled attribute', () => {
      const $input = $('input').first();
      $input.disable();

      expect($input).toHaveAttr('disabled', 'disabled');
    });

    it('adds the disabled class', () => {
      const $input = $('input').first();
      $input.disable();

      expect($input).toHaveClass('disabled');
    });
  });

  describe('enable', () => {
    beforeEach(() => {
      setHTMLFixture('<input type="text" disabled="disabled" class="disabled" />');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('removes the disabled attribute', () => {
      const $input = $('input').first();
      $input.enable();

      expect($input).not.toHaveAttr('disabled');
    });

    it('removes the disabled class', () => {
      const $input = $('input').first();
      $input.enable();

      expect($input).not.toHaveClass('disabled');
    });
  });
});
