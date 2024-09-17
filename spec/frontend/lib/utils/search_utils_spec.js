import { pickProperties, searchInItemsProperties } from '~/lib/utils/search_utils';

const items = [1, 2].map((id) => ({
  id,
  name: `name ${id}`,
  text: `text ${id}`,
  title: `title ${id}`,
}));

describe('pickProperties', () => {
  it.each`
    source       | properties                | outcome
    ${undefined} | ${[]}                     | ${{}}
    ${null}      | ${[]}                     | ${{}}
    ${{}}        | ${[]}                     | ${{}}
    ${items[0]}  | ${[]}                     | ${items[0]}
    ${items[0]}  | ${undefined}              | ${items[0]}
    ${items[0]}  | ${null}                   | ${items[0]}
    ${items[0]}  | ${['name']}               | ${{ name: 'name 1' }}
    ${items[0]}  | ${['name', 'text', 'id']} | ${{ name: 'name 1', text: 'text 1', id: 1 }}
  `('picks specific properties from source object', ({ source, properties, outcome }) => {
    expect(pickProperties(source, properties)).toEqual(outcome);
  });

  it('throws an error if property does not exist on source object', () => {
    try {
      pickProperties(items[0], ['name', 'text1']);
    } catch (error) {
      expect(error).toEqual(
        new Error('text1 does not exist on object. Please provide valid property list.'),
      );
    }
  });
});

describe('searchInItemsProperties', () => {
  it.each`
    items        | properties                   | searchQuery | outcome
    ${undefined} | ${[]}                        | ${''}       | ${[]}
    ${null}      | ${[]}                        | ${''}       | ${[]}
    ${[]}        | ${[]}                        | ${''}       | ${[]}
    ${items}     | ${[]}                        | ${''}       | ${items}
    ${items}     | ${[]}                        | ${'name 1'} | ${[items[0]]}
    ${items}     | ${['text']}                  | ${'name 1'} | ${[]}
    ${items}     | ${['text']}                  | ${'text 1'} | ${[items[0]]}
    ${items}     | ${['text', 'name']}          | ${'text 2'} | ${[items[1]]}
    ${items}     | ${['text', 'name', 'title']} | ${'text 2'} | ${[items[1]]}
    ${items}     | ${['name', 'title']}         | ${'text 2'} | ${[]}
  `(
    'filters items based on search query and picked properties',
    ({ items: mockedItems, properties, searchQuery, outcome }) => {
      expect(searchInItemsProperties({ items: mockedItems, properties, searchQuery })).toEqual(
        outcome,
      );
    },
  );

  it('throws an error if property does not exist on source objects when searched', () => {
    try {
      searchInItemsProperties({ items, properties: ['name', 'text1'], searchQuery: 'text 1' });
    } catch (error) {
      expect(error).toEqual(
        new Error('text1 does not exist on object. Please provide valid property list.'),
      );
    }
  });
});
