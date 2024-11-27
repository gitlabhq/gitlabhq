import {
  generateHelpTextWithLinks,
  mapSystemToFriendlyError,
  isKnownErrorCode,
} from '~/lib/utils/error_utils';
import { convertObjectPropsToLowerCase } from '~/lib/utils/common_utils';

describe('Error Alert Utils', () => {
  const unfriendlyErrorOneKey = 'Unfriendly error 1';
  const emailTakenAttributeMap = 'email:taken';
  const authenticationRequiredCause =
    '[card_error/authentication_required/authentication_required]';
  const emailTakenError = 'Email has already been taken';
  const emailTakenFriendlyError = {
    message: 'This is a friendly error message for the given attribute map',
    links: {},
  };
  const authenticationRequiredError = {
    message:
      '%{stripe3dsLinkStart}3D Secure authentication%{stripe3dsLinkEnd} is not supported. Please %{salesLinkStart}contact our sales team%{salesLinkEnd} to purchase, or try a different credit card.',
    links: {
      stripe3dsLink: 'https://docs.stripe.com/payments/3d-secure',
      salesLink: 'https://example.com/sales/',
    },
  };

  const mockErrorDictionary = convertObjectPropsToLowerCase({
    [unfriendlyErrorOneKey]: {
      message:
        'This is a friendly error with %{linkOneStart}link 1%{linkOneEnd} and %{linkTwoStart}link 2%{linkTwoEnd}',
      links: {
        linkOne: '/sample/link/1',
        linkTwo: '/sample/link/2',
      },
    },
    'Unfriendly error 2': {
      message: 'This is a friendly error with only %{linkStart} one link %{linkEnd}',
      links: {
        link: '/sample/link/1',
      },
    },
    'Unfriendly error 3': {
      message: 'This is a friendly error with no links',
      links: {},
    },
    [emailTakenAttributeMap]: emailTakenFriendlyError,
    [authenticationRequiredCause]: authenticationRequiredError,
    [emailTakenError]: emailTakenFriendlyError,
  });

  const mockGeneralError = {
    message: 'Something went wrong',
    link: {},
  };

  describe('mapSystemToFriendlyError', () => {
    describe.each(Object.keys(mockErrorDictionary))('when system error is %s', (systemError) => {
      const friendlyError = mockErrorDictionary[systemError];

      it('maps the error string the system error to the friendly one', () => {
        expect(mapSystemToFriendlyError(new Error(systemError), mockErrorDictionary)).toEqual(
          friendlyError,
        );
      });

      it('maps error cause to the system error to the friendly one', () => {
        expect(
          mapSystemToFriendlyError(
            new Error(emailTakenError, { cause: systemError }),
            mockErrorDictionary,
          ),
        ).toEqual(friendlyError);
      });

      it('maps the system error to the friendly one from uppercase', () => {
        expect(
          mapSystemToFriendlyError(new Error(systemError.toUpperCase()), mockErrorDictionary),
        ).toEqual(friendlyError);
      });
    });

    describe.each([
      '',
      {},
      [],
      undefined,
      null,
      new Error(),
      new Error(undefined, { cause: null }),
    ])('when system error is %s', (systemError) => {
      it('defaults to the given general error message when provided', () => {
        expect(
          mapSystemToFriendlyError(systemError, mockErrorDictionary, mockGeneralError),
        ).toEqual(mockGeneralError);
      });

      it('defaults to the default error message when general error message is not provided', () => {
        expect(mapSystemToFriendlyError(systemError, mockErrorDictionary)).toEqual({
          message: 'Something went wrong. Please try again.',
          links: {},
        });
      });
    });

    describe('when system error is a non-existent key', () => {
      const message = 'a non-existent key';
      const nonExistentKeyError = { message, links: {} };

      it('maps the system error to the friendly one', () => {
        expect(mapSystemToFriendlyError(new Error(message), mockErrorDictionary)).toEqual(
          nonExistentKeyError,
        );
      });
    });

    describe('when system error consists of multiple non-existent keys', () => {
      const message = 'a non-existent key, another non-existent key';
      const nonExistentKeyError = { message, links: {} };

      it('maps the system error to the friendly one', () => {
        expect(mapSystemToFriendlyError(new Error(message), mockErrorDictionary)).toEqual(
          nonExistentKeyError,
        );
      });
    });

    describe('when system error consists of multiple messages with one matching key', () => {
      const message = `a non-existent key, ${unfriendlyErrorOneKey}`;

      it('maps the system error to the friendly one', () => {
        expect(mapSystemToFriendlyError(new Error(message), mockErrorDictionary)).toEqual(
          mockErrorDictionary[unfriendlyErrorOneKey.toLowerCase()],
        );
      });
    });

    describe('when error cause does not exist', () => {
      it('maps the error string', () => {
        expect(
          mapSystemToFriendlyError(
            new Error(unfriendlyErrorOneKey, { cause: 'does not exist' }),
            mockErrorDictionary,
          ),
        ).toEqual(mockErrorDictionary[unfriendlyErrorOneKey.toLowerCase()]);
      });
    });

    describe('when both error cause and error string exists', () => {
      it('maps the error cause', () => {
        expect(
          mapSystemToFriendlyError(
            new Error(unfriendlyErrorOneKey, { cause: authenticationRequiredCause }),
            mockErrorDictionary,
          ),
        ).toEqual(mockErrorDictionary[authenticationRequiredCause.toLowerCase()]);
      });
    });
  });

  describe('generateHelpTextWithLinks', () => {
    describe('when the error is present in the dictionary', () => {
      describe.each(Object.values(mockErrorDictionary))(
        'when system error is %s',
        (friendlyError) => {
          it('generates the proper link', () => {
            const errorHtmlString = generateHelpTextWithLinks(friendlyError);
            const expected = Array.from(friendlyError.message.matchAll(/%{/g)).length / 2;
            const newNode = document.createElement('div');
            newNode.innerHTML = errorHtmlString;
            const links = Array.from(newNode.querySelectorAll('a'));

            expect(links).toHaveLength(expected);
          });
        },
      );
    });

    describe('when the error contains no links', () => {
      it('generates the proper link/s', () => {
        const anError = { message: 'An error', links: {} };
        const errorHtmlString = generateHelpTextWithLinks(anError);
        const expected = Object.keys(anError.links).length;
        const newNode = document.createElement('div');
        newNode.innerHTML = errorHtmlString;
        const links = Array.from(newNode.querySelectorAll('a'));

        expect(links).toHaveLength(expected);
      });
    });

    describe('when the error is invalid', () => {
      it('returns the error', () => {
        expect(() => generateHelpTextWithLinks([])).toThrow(
          new Error('The error cannot be empty.'),
        );
      });
    });

    describe('when the error is not an object', () => {
      it('returns the error', () => {
        const errorHtmlString = generateHelpTextWithLinks('An error');

        expect(errorHtmlString).toBe('An error');
      });
    });

    describe('when the error is falsy', () => {
      it('throws an error', () => {
        expect(() => generateHelpTextWithLinks(null)).toThrow(
          new Error('The error cannot be empty.'),
        );
      });
    });
  });

  describe('isKnownErrorCode', () => {
    const errorDictionary = {
      known_error_code: 'Friendly error for known error code',
    };

    it.each`
      error                   | result
      ${'known_error_code'}   | ${true}
      ${'unknown_error_code'} | ${false}
      ${new Error()}          | ${false}
      ${1000}                 | ${false}
      ${''}                   | ${false}
      ${{}}                   | ${false}
      ${[]}                   | ${false}
      ${undefined}            | ${false}
      ${null}                 | ${false}
    `('returns $result when error is $error', ({ error, result }) => {
      expect(isKnownErrorCode(error, errorDictionary)).toBe(result);
    });
  });
});
