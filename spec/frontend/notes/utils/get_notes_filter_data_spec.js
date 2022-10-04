import { getNotesFilterData } from '~/notes/utils/get_notes_filter_data';
import { notesFilters } from '../mock_data';

// what: This is the format we expect the element attribute to be in
// why: For readability, we make this clear by hardcoding the indecise instead of using `reduce`.
const TEST_NOTES_FILTERS_ATTR = {
  [notesFilters[0].title]: notesFilters[0].value,
  [notesFilters[1].title]: notesFilters[1].value,
  [notesFilters[2].title]: notesFilters[2].value,
};

describe('~/notes/utils/get_notes_filter_data', () => {
  it.each([
    {
      desc: 'empty',
      attributes: {},
      expectation: {
        notesFilters: [],
        notesFilterValue: undefined,
      },
    },
    {
      desc: 'valid attributes',
      attributes: {
        'data-notes-filters': JSON.stringify(TEST_NOTES_FILTERS_ATTR),
        'data-notes-filter-value': '1',
      },
      expectation: {
        notesFilters,
        notesFilterValue: 1,
      },
    },
  ])('with $desc, parses data from element attributes', ({ attributes, expectation }) => {
    const el = document.createElement('div');

    Object.entries(attributes).forEach(([key, value]) => {
      el.setAttribute(key, value);
    });

    const actual = getNotesFilterData(el);

    expect(actual).toStrictEqual(expectation);
  });
});
