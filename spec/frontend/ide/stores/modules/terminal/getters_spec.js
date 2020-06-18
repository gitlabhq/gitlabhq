import { CHECK_CONFIG, CHECK_RUNNERS } from '~/ide/stores/modules/terminal/constants';
import * as getters from '~/ide/stores/modules/terminal/getters';

describe('IDE store terminal getters', () => {
  describe('allCheck', () => {
    it('is loading if one check is loading', () => {
      const checks = {
        [CHECK_CONFIG]: { isLoading: false, isValid: true },
        [CHECK_RUNNERS]: { isLoading: true },
      };

      const result = getters.allCheck({ checks });

      expect(result).toEqual({
        isLoading: true,
      });
    });

    it('is invalid if one check is invalid', () => {
      const message = 'lorem ipsum';
      const checks = {
        [CHECK_CONFIG]: { isLoading: false, isValid: false, message },
        [CHECK_RUNNERS]: { isLoading: false, isValid: true },
      };

      const result = getters.allCheck({ checks });

      expect(result).toEqual({
        isLoading: false,
        isValid: false,
        message,
      });
    });

    it('is valid if all checks are valid', () => {
      const checks = {
        [CHECK_CONFIG]: { isLoading: false, isValid: true },
        [CHECK_RUNNERS]: { isLoading: false, isValid: true },
      };

      const result = getters.allCheck({ checks });

      expect(result).toEqual({
        isLoading: false,
        isValid: true,
        message: '',
      });
    });
  });
});
