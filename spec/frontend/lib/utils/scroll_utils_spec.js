import { isScrolledToBottom } from '~/lib/utils/scroll_utils';

describe('isScrolledToBottom', () => {
  const setScrollGetters = (getters) => {
    Object.entries(getters).forEach(([name, value]) => {
      jest.spyOn(Element.prototype, name, 'get').mockReturnValue(value);
    });
  };

  it.each`
    context                                                           | scrollTop | scrollHeight | result
    ${'returns false when not scrolled to bottom'}                    | ${0}      | ${2000}      | ${false}
    ${'returns true when scrolled to bottom'}                         | ${1000}   | ${2000}      | ${true}
    ${'returns true when scrolled to bottom with subpixel precision'} | ${999.25} | ${2000}      | ${true}
    ${'returns true when cannot scroll'}                              | ${0}      | ${500}       | ${true}
  `('$context', ({ scrollTop, scrollHeight, result }) => {
    setScrollGetters({ scrollTop, clientHeight: 1000, scrollHeight });

    expect(isScrolledToBottom()).toBe(result);
  });
});
