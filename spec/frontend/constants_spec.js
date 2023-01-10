import * as constants from '~/constants';

describe('Global JS constants', () => {
  describe('getModifierKey()', () => {
    afterEach(() => {
      delete window.gl;
    });

    it.each`
      isMac    | removeSuffix | expectedKey
      ${true}  | ${false}     | ${'⌘'}
      ${false} | ${false}     | ${'Ctrl+'}
      ${true}  | ${true}      | ${'⌘'}
      ${false} | ${true}      | ${'Ctrl'}
    `(
      'returns correct keystroke when isMac=$isMac and removeSuffix=$removeSuffix',
      ({ isMac, removeSuffix, expectedKey }) => {
        Object.assign(window, {
          gl: {
            client: {
              isMac,
            },
          },
        });

        expect(constants.getModifierKey(removeSuffix)).toBe(expectedKey);
      },
    );
  });
});
