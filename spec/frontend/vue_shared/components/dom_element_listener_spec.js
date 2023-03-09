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

  const createComponent = () => {
    wrapper = mount(DomElementListener, {
      propsData: {
        selector: SELECTOR,
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

  describe('default', () => {
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

  describe('after destroyed', () => {
    beforeEach(() => {
      createComponent();
      wrapper.destroy();
    });

    describe('when matching element triggers event', () => {
      beforeEach(() => {
        findElement('lorem').dispatchEvent(new Event('click'));
      });

      it('does not trigger any listeners', () => {
        expect(spiesCallCount()).toBe(0);
      });
    });
  });
});
