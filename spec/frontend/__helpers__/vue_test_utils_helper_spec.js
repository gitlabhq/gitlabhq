import * as testingLibrary from '@testing-library/dom';
import * as vtu from '@vue/test-utils';
import {
  shallowMount,
  Wrapper as VTUWrapper,
  WrapperArray as VTUWrapperArray,
  ErrorWrapper as VTUErrorWrapper,
} from '@vue/test-utils';
import Vue from 'vue';
import { extendedWrapper, shallowMountExtended, mountExtended } from './vue_test_utils_helper';

jest.mock('@testing-library/dom', () => ({
  __esModule: true,
  ...jest.requireActual('@testing-library/dom'),
}));

describe('Vue test utils helpers', () => {
  afterAll(() => {
    jest.unmock('@testing-library/dom');
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

      it('should find the element by test id', () => {
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

    describe('findComponentByTestId', () => {
      const testId = 'a-component';
      let mockChild;
      let mockComponent;

      beforeEach(() => {
        mockChild = {
          template: '<div></div>',
        };
        mockComponent = extendedWrapper(
          shallowMount({
            render(h) {
              return h('div', {}, [h(mockChild, { attrs: { 'data-testid': testId } })]);
            },
          }),
        );
      });

      it('should find the element by test id', () => {
        expect(mockComponent.findComponentByTestId(testId).exists()).toBe(true);
      });
    });

    describe('findAllComponentsByTestId', () => {
      const testId = 'a-component';
      let mockComponent;
      let mockChild;

      beforeEach(() => {
        mockChild = {
          template: `<div></div>`,
        };
        mockComponent = extendedWrapper(
          shallowMount({
            render(h) {
              return h('div', [
                h(mockChild, { attrs: { 'data-testid': testId } }),
                h(mockChild, { attrs: { 'data-testid': testId } }),
              ]);
            },
          }),
        );
      });

      it('should find all components by test id', () => {
        expect(mockComponent.findAllComponentsByTestId(testId)).toHaveLength(2);
      });
    });

    describe.each`
      findMethod                 | expectedQuery
      ${'findByRole'}            | ${'queryAllByRole'}
      ${'findByLabelText'}       | ${'queryAllByLabelText'}
      ${'findByPlaceholderText'} | ${'queryAllByPlaceholderText'}
      ${'findByText'}            | ${'queryAllByText'}
      ${'findByDisplayValue'}    | ${'queryAllByDisplayValue'}
      ${'findByAltText'}         | ${'queryAllByAltText'}
    `('$findMethod', ({ findMethod, expectedQuery }) => {
      const text = 'foo bar';
      const options = { selector: 'div' };
      const mockDiv = document.createElement('div');

      let wrapper;
      beforeEach(() => {
        jest.spyOn(vtu, 'createWrapper');

        wrapper = extendedWrapper(
          shallowMount({
            template: `<div>foo bar</div>`,
          }),
        );
      });

      it(`calls Testing Library \`${expectedQuery}\` function with correct parameters`, () => {
        jest.spyOn(testingLibrary, expectedQuery).mockImplementation(() => [mockDiv]);

        wrapper[findMethod](text, options);

        expect(testingLibrary[expectedQuery]).toHaveBeenLastCalledWith(
          wrapper.element,
          text,
          options,
        );
      });

      describe('when element is found', () => {
        beforeEach(() => {
          jest.spyOn(testingLibrary, expectedQuery).mockImplementation(() => [mockDiv]);
        });

        it('returns a VTU wrapper', () => {
          const result = wrapper[findMethod](text, options);

          expect(vtu.createWrapper).toHaveBeenCalledWith(mockDiv, wrapper.options);
          expect(result).toBeInstanceOf(VTUWrapper);
          expect(result.vm).toBeUndefined();
        });
      });

      describe('when multiple elements are found', () => {
        beforeEach(() => {
          const mockSpan = document.createElement('span');
          jest.spyOn(testingLibrary, expectedQuery).mockImplementation(() => [mockDiv, mockSpan]);
        });

        it('returns the first element as a VTU wrapper', () => {
          const result = wrapper[findMethod](text, options);

          expect(vtu.createWrapper).toHaveBeenCalledWith(mockDiv, wrapper.options);
          expect(result).toBeInstanceOf(VTUWrapper);
          expect(result.vm).toBeUndefined();
        });
      });

      describe('when element is not found', () => {
        beforeEach(() => {
          jest.spyOn(testingLibrary, expectedQuery).mockImplementation(() => []);
        });

        it('returns a VTU error wrapper', () => {
          expect(wrapper[findMethod](text, options)).toBeInstanceOf(VTUErrorWrapper);
        });
      });
    });

    describe.each`
      findMethod                    | expectedQuery
      ${'findAllByRole'}            | ${'queryAllByRole'}
      ${'findAllByLabelText'}       | ${'queryAllByLabelText'}
      ${'findAllByPlaceholderText'} | ${'queryAllByPlaceholderText'}
      ${'findAllByText'}            | ${'queryAllByText'}
      ${'findAllByDisplayValue'}    | ${'queryAllByDisplayValue'}
      ${'findAllByAltText'}         | ${'queryAllByAltText'}
    `('$findMethod', ({ findMethod, expectedQuery }) => {
      const text = 'foo bar';
      const options = { selector: 'li' };
      const mockElements = [
        document.createElement('li'),
        document.createElement('li'),
        document.createElement('li'),
      ];
      const mockVms = [
        new Vue({ render: (h) => h('li') }).$mount(),
        new Vue({ render: (h) => h('li') }).$mount(),
        new Vue({ render: (h) => h('li') }).$mount(),
      ];

      let wrapper;
      beforeEach(() => {
        wrapper = extendedWrapper(
          shallowMount({
            template: `
              <ul>
                <li>foo</li>
                <li>bar</li>
                <li>baz</li>
              </ul>
            `,
          }),
        );
      });

      it(`calls Testing Library \`${expectedQuery}\` function with correct parameters`, () => {
        jest.spyOn(testingLibrary, expectedQuery).mockImplementation(() => mockElements);

        wrapper[findMethod](text, options);

        expect(testingLibrary[expectedQuery]).toHaveBeenLastCalledWith(
          wrapper.element,
          text,
          options,
        );
      });

      describe.each`
        case                       | mockResult      | isVueInstance
        ${'HTMLElements'}          | ${mockElements} | ${false}
        ${'Vue instance elements'} | ${mockVms}      | ${true}
      `('when $case are found', ({ mockResult, isVueInstance }) => {
        beforeEach(() => {
          jest.spyOn(testingLibrary, expectedQuery).mockImplementation(() => mockResult);
        });

        it('returns a VTU wrapper array', () => {
          const result = wrapper[findMethod](text, options);

          expect(result).toBeInstanceOf(VTUWrapperArray);
          expect(
            result.wrappers.every(
              (resultWrapper) =>
                resultWrapper instanceof VTUWrapper &&
                resultWrapper.vm instanceof Vue === isVueInstance &&
                resultWrapper.options === wrapper.options,
            ),
          ).toBe(true);
          expect(result.length).toBe(3);
        });
      });

      describe('when elements are not found', () => {
        beforeEach(() => {
          jest.spyOn(testingLibrary, expectedQuery).mockImplementation(() => []);
        });

        it('returns an empty VTU wrapper array', () => {
          const result = wrapper[findMethod](text, options);

          expect(result).toBeInstanceOf(VTUWrapperArray);
          expect(result.length).toBe(0);
        });
      });
    });
  });

  describe('mount extended functions', () => {
    // eslint-disable-next-line vue/one-component-per-file
    const FakeChildComponent = Vue.component('FakeChildComponent', {
      template: '<div>Bar <div data-testid="fake-id"/></div>',
    });

    // eslint-disable-next-line vue/one-component-per-file
    const FakeComponent = Vue.component('FakeComponent', {
      components: {
        FakeChildComponent,
      },
      template: '<div>Foo <fake-child-component data-testid="fake-id" /></div>',
    });

    describe('mountExtended', () => {
      it('mounts component and provides extended queries', () => {
        const wrapper = mountExtended(FakeComponent);
        expect(wrapper.text()).toBe('Foo Bar');
        expect(wrapper.findAllByTestId('fake-id').length).toBe(2);
      });
    });

    describe('shallowMountExtended', () => {
      it('shallow mounts component and provides extended queries', () => {
        const wrapper = shallowMountExtended(FakeComponent);
        expect(wrapper.text()).toBe('Foo');
        expect(wrapper.findAllByTestId('fake-id').length).toBe(1);
      });
    });
  });
});
