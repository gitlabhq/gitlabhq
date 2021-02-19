import { shallowMount } from '@vue/test-utils';
import { extendedWrapper, shallowWrapperContainsSlotText } from './vue_test_utils_helper';

describe('Vue test utils helpers', () => {
  describe('shallowWrapperContainsSlotText', () => {
    const mockText = 'text';
    const mockSlot = `<div>${mockText}</div>`;
    let mockComponent;

    beforeEach(() => {
      mockComponent = shallowMount(
        {
          render(h) {
            h(`<div>mockedComponent</div>`);
          },
        },
        {
          slots: {
            default: mockText,
            namedSlot: mockSlot,
          },
        },
      );
    });

    it('finds text within shallowWrapper default slot', () => {
      expect(shallowWrapperContainsSlotText(mockComponent, 'default', mockText)).toBe(true);
    });

    it('finds text within shallowWrapper named slot', () => {
      expect(shallowWrapperContainsSlotText(mockComponent, 'namedSlot', mockText)).toBe(true);
    });

    it('returns false when text is not present', () => {
      const searchText = 'absent';

      expect(shallowWrapperContainsSlotText(mockComponent, 'default', searchText)).toBe(false);
      expect(shallowWrapperContainsSlotText(mockComponent, 'namedSlot', searchText)).toBe(false);
    });

    it('searches with case-sensitivity', () => {
      const searchText = mockText.toUpperCase();

      expect(shallowWrapperContainsSlotText(mockComponent, 'default', searchText)).toBe(false);
      expect(shallowWrapperContainsSlotText(mockComponent, 'namedSlot', searchText)).toBe(false);
    });
  });

  describe('extendedWrapper', () => {
    describe('when an invalid wrapper is provided', () => {
      beforeEach(() => {
        // eslint-disable-next-line no-console
        console.warn = jest.fn();
      });

      it.each`
        wrapper
        ${{}}
        ${[]}
        ${null}
        ${undefined}
        ${1}
        ${''}
      `('should warn with an error when the wrapper is $wrapper', ({ wrapper }) => {
        extendedWrapper(wrapper);
        /* eslint-disable no-console */
        expect(console.warn).toHaveBeenCalled();
        expect(console.warn).toHaveBeenCalledWith(
          '[vue-test-utils-helper]: you are trying to extend an object that is not a VueWrapper.',
        );
        /* eslint-enable no-console */
      });
    });

    describe('findByTestId', () => {
      const testId = 'a-component';
      let mockComponent;

      beforeEach(() => {
        mockComponent = extendedWrapper(
          shallowMount({
            template: `<div data-testid="${testId}"></div>`,
          }),
        );
      });

      it('should find the component by test id', () => {
        expect(mockComponent.findByTestId(testId).exists()).toBe(true);
      });
    });

    describe('findAllByTestId', () => {
      const testId = 'a-component';
      let mockComponent;

      beforeEach(() => {
        mockComponent = extendedWrapper(
          shallowMount({
            template: `<div><div data-testid="${testId}"></div><div data-testid="${testId}"></div></div>`,
          }),
        );
      });

      it('should find all components by test id', () => {
        expect(mockComponent.findAllByTestId(testId)).toHaveLength(2);
      });
    });
  });
});
