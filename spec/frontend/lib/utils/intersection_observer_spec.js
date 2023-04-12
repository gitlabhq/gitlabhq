import { create } from '~/lib/utils/intersection_observer';

describe('IntersectionObserver Utility', () => {
  beforeAll(() => {
    global.IntersectionObserver = class MockIntersectionObserver {
      constructor(callback) {
        this.callback = callback;

        this.entries = [];
      }

      addEntry(entry) {
        this.entries.push(entry);
      }

      trigger() {
        this.callback(this.entries);
      }
    };
  });
  describe('create', () => {
    describe('memoization', () => {
      const options = { rootMargin: '1px 1px 1px 1px' };
      let expectedOutput;

      beforeEach(() => {
        create.cache.clear();
        expectedOutput = create(options);
      });

      it('returns the same Observer for the same options input', () => {
        expect(expectedOutput.id).toBe(create(options).id);
      });

      it('creates a new Observer for unique input options', () => {
        expect(expectedOutput.id).not.toBe(create({ rootMargin: '1px 2px 3px 4px' }));
      });

      it('creates a new Observer for the same input options in different object references', () => {
        expect(expectedOutput.id).not.toBe(create({ rootMargin: '1px 1px 1px 1px' }));
      });
    });
  });

  describe('Observer behavior', () => {
    let observer = null;
    let id = null;

    beforeEach(() => {
      create.cache.clear();
      ({ observer, id } = create());
    });

    it.each`
      isIntersecting | event
      ${false}       | ${'IntersectionDisappear'}
      ${true}        | ${'IntersectionAppear'}
    `(
      'should emit the correct event on the entry target based on the computed Intersection',
      ({ isIntersecting, event }) => {
        const target = document.createElement('div');
        observer.addEntry({ target, isIntersecting });

        target.addEventListener(event, (e) => {
          expect(e.detail.observer).toBe(id);
        });

        observer.trigger();
      },
    );

    it('should always emit an Update event with the entry and the observer', () => {
      const target = document.createElement('div');
      const entry = { target };

      observer.addEntry(entry);

      target.addEventListener('IntersectionUpdate', (e) => {
        expect(e.detail.observer).toBe(id);
        expect(e.detail.entry).toStrictEqual(entry);
      });

      observer.trigger();
    });
  });
});
