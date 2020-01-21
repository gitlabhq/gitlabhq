import * as constants from '~/droplab/constants';

describe('constants', () => {
  describe('DATA_TRIGGER', () => {
    it('should be `data-dropdown-trigger`', () => {
      expect(constants.DATA_TRIGGER).toBe('data-dropdown-trigger');
    });
  });

  describe('DATA_DROPDOWN', () => {
    it('should be `data-dropdown`', () => {
      expect(constants.DATA_DROPDOWN).toBe('data-dropdown');
    });
  });

  describe('SELECTED_CLASS', () => {
    it('should be `droplab-item-selected`', () => {
      expect(constants.SELECTED_CLASS).toBe('droplab-item-selected');
    });
  });

  describe('ACTIVE_CLASS', () => {
    it('should be `droplab-item-active`', () => {
      expect(constants.ACTIVE_CLASS).toBe('droplab-item-active');
    });
  });

  describe('TEMPLATE_REGEX', () => {
    it('should be a handlebars templating syntax regex', () => {
      expect(constants.TEMPLATE_REGEX).toEqual(/\{\{(.+?)\}\}/g);
    });
  });

  describe('IGNORE_CLASS', () => {
    it('should be `droplab-item-ignore`', () => {
      expect(constants.IGNORE_CLASS).toBe('droplab-item-ignore');
    });
  });
});
