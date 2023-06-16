import { getSelectedOptionsText } from '~/lib/utils/listbox_helpers';

describe('getSelectedOptionsText', () => {
  it('returns an empty string per default when no options are selected', () => {
    const options = [
      { id: 1, text: 'first' },
      { id: 2, text: 'second' },
    ];
    const selected = [];

    expect(getSelectedOptionsText({ options, selected })).toBe('');
  });

  it('returns the provided placeholder when no options are selected', () => {
    const options = [
      { id: 1, text: 'first' },
      { id: 2, text: 'second' },
    ];
    const selected = [];
    const placeholder = 'placeholder';

    expect(getSelectedOptionsText({ options, selected, placeholder })).toBe(placeholder);
  });

  describe('maxOptionsShown is not provided', () => {
    it('returns the text of the first selected option when only one option is selected', () => {
      const options = [{ id: 1, text: 'first' }];
      const selected = [options[0].id];

      expect(getSelectedOptionsText({ options, selected })).toBe('first');
    });

    it('should also work with the value property', () => {
      const options = [{ value: 1, text: 'first' }];
      const selected = [options[0].value];

      expect(getSelectedOptionsText({ options, selected })).toBe('first');
    });

    it.each`
      options                                                                            | expectedText
      ${[{ id: 1, text: 'first' }, { id: 2, text: 'second' }]}                           | ${'first +1 more'}
      ${[{ id: 1, text: 'first' }, { id: 2, text: 'second' }, { id: 3, text: 'third' }]} | ${'first +2 more'}
    `(
      'returns "$expectedText" when more than one option is selected',
      ({ options, expectedText }) => {
        const selected = options.map(({ id }) => id);

        expect(getSelectedOptionsText({ options, selected })).toBe(expectedText);
      },
    );
  });

  describe('maxOptionsShown > 1', () => {
    const options = [
      { id: 1, text: 'first' },
      { id: 2, text: 'second' },
      { id: 3, text: 'third' },
      { id: 4, text: 'fourth' },
      { id: 5, text: 'fifth' },
    ];

    it.each`
      selected           | maxOptionsShown | expectedText
      ${[1]}             | ${2}            | ${'first'}
      ${[1, 2]}          | ${2}            | ${'first, second'}
      ${[1, 2, 3]}       | ${2}            | ${'first, second +1 more'}
      ${[1, 2, 3]}       | ${3}            | ${'first, second, third'}
      ${[1, 2, 3, 4]}    | ${3}            | ${'first, second, third +1 more'}
      ${[1, 2, 3, 4, 5]} | ${3}            | ${'first, second, third +2 more'}
    `(
      'returns "$expectedText" when "$selected.length" options are selected and maxOptionsShown is "$maxOptionsShown"',
      ({ selected, maxOptionsShown, expectedText }) => {
        expect(getSelectedOptionsText({ options, selected, maxOptionsShown })).toBe(expectedText);
      },
    );
  });

  it('ignores selected options that are not in the options array', () => {
    const options = [
      { id: 1, text: 'first' },
      { id: 2, text: 'second' },
    ];
    const invalidOption = { id: 3, text: 'third' };
    const selected = [options[0].id, options[1].id, invalidOption.id];

    expect(getSelectedOptionsText({ options, selected })).toBe('first +1 more');
  });
});
