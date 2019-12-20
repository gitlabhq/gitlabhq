import $ from 'jquery';
import '~/commons/bootstrap';

describe('Bootstrap jQuery extensions', () => {
  describe('disable', () => {
    beforeEach(() => {
      setFixtures('<input type="text" />');
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
      setFixtures('<input type="text" disabled="disabled" class="disabled" />');
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
