import createState from '~/integrations/edit/store/state';

describe('Integration form state factory', () => {
  it('states default to null', () => {
    expect(createState()).toEqual({
      adminState: null,
      customState: {},
      override: false,
    });
  });

  describe('override is initialized correctly', () => {
    it.each([
      [{ id: 25 }, { inheritFromId: null }, true],
      [{ id: 25 }, { inheritFromId: 27 }, true],
      [{ id: 25 }, { inheritFromId: 25 }, false],
      [null, { inheritFromId: null }, false],
      [null, { inheritFromId: 25 }, false],
    ])(
      'for adminState: %p, customState: %p: override = `%p`',
      (adminState, customState, expected) => {
        expect(createState({ adminState, customState }).override).toEqual(expected);
      },
    );
  });
});
