import { mount } from '@vue/test-utils';
import { setHTMLFixture } from 'helpers/fixtures';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';

const DEFAULT_SLOT_CONTENT = 'Default slot content';
const SELECTOR = '.js-test-include';
const HTML = `
<div>
  <button class="js-test-include" data-testid="lorem">Lorem</button>
  <button class="js-test-include" data-testid="ipsum">Ipsum</button>
  <button data-testid="hello">Hello</a>
</div>
`;

describe('~/vue_shared/components/dom_element_listener.vue', () => {
  let wrapper;
  let spies;

  const createComponent = (props = {}) => {
    wrapper = mount(DomElementListener, {
      propsData: {
        selector: SELECTOR,
        ...props,
      },
      listeners: spies,
      slots: {
        default: DEFAULT_SLOT_CONTENT,
      },
    });
  };

  const findElement = (testId) => document.querySelector(`[data-testid="${testId}"]`);
  const spiesCallCount = () =>
    Object.values(spies)
      .map((x) => x.mock.calls.length)
      .reduce((a, b) => a + b);

  beforeEach(() => {
    setHTMLFixture(HTML);
    spies = {
      click: jest.fn(),
      focus: jest.fn(),
    };
  });

  describe('default behavior (direct attachment)', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders default slot', () => {
      expect(wrapper.text()).toBe(DEFAULT_SLOT_CONTENT);
    });

    it('does not initially trigger listeners', () => {
      expect(spiesCallCount()).toBe(0);
    });

    describe.each`
      event      | testId
      ${'click'} | ${'lorem'}
      ${'focus'} | ${'ipsum'}
    `(
      'when matching element triggers event (testId=$testId, event=$event)',
      ({ event, testId }) => {
        beforeEach(() => {
          findElement(testId).dispatchEvent(new Event(event));
        });

        it('triggers listener', () => {
          expect(spiesCallCount()).toBe(1);
          expect(spies[event]).toHaveBeenCalledWith(expect.any(Event));
          expect(spies[event]).toHaveBeenCalledWith(
            expect.objectContaining({
              target: findElement(testId),
            }),
          );
        });
      },
    );

    describe.each`
      desc                                                 | event      | testId
      ${'when non-matching element triggers event'}        | ${'click'} | ${'hello'}
      ${'when matching element triggers unlistened event'} | ${'hover'} | ${'lorem'}
    `('$desc', ({ event, testId }) => {
      beforeEach(() => {
        findElement(testId).dispatchEvent(new Event(event));
      });

      it('does not trigger listeners', () => {
        expect(spiesCallCount()).toBe(0);
      });
    });
  });

  describe('event delegation mode', () => {
    beforeEach(() => {
      createComponent({ useEventDelegation: true });
    });

    it('renders default slot', () => {
      expect(wrapper.text()).toBe(DEFAULT_SLOT_CONTENT);
    });

    it('does not initially trigger listeners', () => {
      expect(spiesCallCount()).toBe(0);
    });

    describe.each`
      event      | testId
      ${'click'} | ${'lorem'}
      ${'focus'} | ${'ipsum'}
    `(
      'when matching element triggers event (testId=$testId, event=$event)',
      ({ event, testId }) => {
        beforeEach(() => {
          findElement(testId).dispatchEvent(new Event(event, { bubbles: true }));
        });

        it('triggers listener', () => {
          expect(spiesCallCount()).toBe(1);
          expect(spies[event]).toHaveBeenCalledWith(expect.any(Event));
          expect(spies[event]).toHaveBeenCalledWith(
            expect.objectContaining({
              target: findElement(testId),
            }),
          );
        });
      },
    );

    describe.each`
      desc                                                 | event      | testId
      ${'when non-matching element triggers event'}        | ${'click'} | ${'hello'}
      ${'when matching element triggers unlistened event'} | ${'hover'} | ${'lorem'}
    `('$desc', ({ event, testId }) => {
      beforeEach(() => {
        findElement(testId).dispatchEvent(new Event(event, { bubbles: true }));
      });

      it('does not trigger listeners', () => {
        expect(spiesCallCount()).toBe(0);
      });
    });

    describe('when element is added dynamically after mount', () => {
      let dynamicElement;

      beforeEach(() => {
        // Add a new matching element to the DOM after component is mounted
        dynamicElement = document.createElement('button');
        dynamicElement.className = 'js-test-include';
        dynamicElement.dataset.testid = 'dynamic';
        dynamicElement.textContent = 'Dynamic';
        document.body.appendChild(dynamicElement);
      });

      afterEach(() => {
        if (dynamicElement && dynamicElement.parentNode) {
          dynamicElement.parentNode.removeChild(dynamicElement);
        }
      });

      it('triggers listener for dynamically added element', () => {
        dynamicElement.dispatchEvent(new Event('click', { bubbles: true }));

        expect(spiesCallCount()).toBe(1);
        expect(spies.click).toHaveBeenCalledWith(expect.any(Event));
        expect(spies.click).toHaveBeenCalledWith(
          expect.objectContaining({
            target: dynamicElement,
          }),
        );
      });
    });

    describe('when element is nested inside matching element', () => {
      let nestedElement;

      beforeEach(() => {
        // Add a nested element inside a matching element
        nestedElement = document.createElement('span');
        nestedElement.dataset.testid = 'nested';
        nestedElement.textContent = 'Nested';
        findElement('lorem').appendChild(nestedElement);
      });

      it('triggers listener when nested element is clicked', () => {
        nestedElement.dispatchEvent(new Event('click', { bubbles: true }));

        expect(spiesCallCount()).toBe(1);
        expect(spies.click).toHaveBeenCalledWith(expect.any(Event));
        expect(spies.click).toHaveBeenCalledWith(
          expect.objectContaining({
            target: nestedElement,
          }),
        );
      });
    });
  });

  describe('after destroyed', () => {
    describe('direct attachment mode', () => {
      beforeEach(() => {
        createComponent();
        wrapper.destroy();
      });

      it('does not trigger any listeners', () => {
        findElement('lorem').dispatchEvent(new Event('click'));
        expect(spiesCallCount()).toBe(0);
      });
    });

    describe('event delegation mode', () => {
      beforeEach(() => {
        createComponent({ useEventDelegation: true });
        wrapper.destroy();
      });

      it('does not trigger any listeners', () => {
        findElement('lorem').dispatchEvent(new Event('click', { bubbles: true }));
        expect(spiesCallCount()).toBe(0);
      });
    });
  });
});
