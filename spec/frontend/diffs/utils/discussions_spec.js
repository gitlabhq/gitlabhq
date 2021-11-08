import { discussionIntersectionObserverHandlerFactory } from '~/diffs/utils/discussions';

describe('Diff Discussions Utils', () => {
  describe('discussionIntersectionObserverHandlerFactory', () => {
    it('creates a handler function', () => {
      expect(discussionIntersectionObserverHandlerFactory()).toBeInstanceOf(Function);
    });

    describe('intersection observer handler', () => {
      const functions = {
        setCurrentDiscussionId: jest.fn(),
        getPreviousUnresolvedDiscussionId: jest.fn().mockImplementation((id) => {
          return Number(id) - 1;
        }),
      };
      const defaultProcessableWrapper = {
        entry: {
          time: 0,
          isIntersecting: true,
          rootBounds: {
            bottom: 0,
          },
          boundingClientRect: {
            top: 0,
          },
        },
        currentDiscussion: {
          id: 1,
        },
        isFirstUnresolved: false,
        isDiffsPage: true,
      };
      let handler;
      let getMock;
      let setMock;

      beforeEach(() => {
        functions.setCurrentDiscussionId.mockClear();
        functions.getPreviousUnresolvedDiscussionId.mockClear();

        defaultProcessableWrapper.functions = functions;

        setMock = functions.setCurrentDiscussionId.mock;
        getMock = functions.getPreviousUnresolvedDiscussionId.mock;
        handler = discussionIntersectionObserverHandlerFactory();
      });

      it('debounces multiple simultaneous requests into one queue', () => {
        handler(defaultProcessableWrapper);
        handler(defaultProcessableWrapper);
        handler(defaultProcessableWrapper);
        handler(defaultProcessableWrapper);

        expect(setTimeout).toHaveBeenCalledTimes(4);
        expect(clearTimeout).toHaveBeenCalledTimes(3);

        // By only advancing to one timer, we ensure it's all being batched into one queue
        jest.advanceTimersToNextTimer();

        expect(functions.setCurrentDiscussionId).toHaveBeenCalledTimes(4);
      });

      it('properly processes, sorts and executes the correct actions for a set of observed intersections', () => {
        handler(defaultProcessableWrapper);
        handler({
          // This observation is here to be filtered out because it's a scrollDown
          ...defaultProcessableWrapper,
          entry: {
            ...defaultProcessableWrapper.entry,
            isIntersecting: false,
            boundingClientRect: { top: 10 },
            rootBounds: { bottom: 100 },
          },
        });
        handler({
          ...defaultProcessableWrapper,
          entry: {
            ...defaultProcessableWrapper.entry,
            time: 101,
            isIntersecting: false,
            rootBounds: { bottom: -100 },
          },
          currentDiscussion: { id: 20 },
        });
        handler({
          ...defaultProcessableWrapper,
          entry: {
            ...defaultProcessableWrapper.entry,
            time: 100,
            isIntersecting: false,
            boundingClientRect: { top: 100 },
          },
          currentDiscussion: { id: 30 },
          isDiffsPage: false,
        });
        handler({
          ...defaultProcessableWrapper,
          isFirstUnresolved: true,
          entry: {
            ...defaultProcessableWrapper.entry,
            time: 100,
            isIntersecting: false,
            boundingClientRect: { top: 200 },
          },
        });

        jest.advanceTimersToNextTimer();

        expect(setMock.calls.length).toBe(4);
        expect(setMock.calls[0]).toEqual([1]);
        expect(setMock.calls[1]).toEqual([29]);
        expect(setMock.calls[2]).toEqual([null]);
        expect(setMock.calls[3]).toEqual([19]);

        expect(getMock.calls.length).toBe(2);
        expect(getMock.calls[0]).toEqual([30, false]);
        expect(getMock.calls[1]).toEqual([20, true]);

        [
          setMock.invocationCallOrder[0],
          getMock.invocationCallOrder[0],
          setMock.invocationCallOrder[1],
          setMock.invocationCallOrder[2],
          getMock.invocationCallOrder[1],
          setMock.invocationCallOrder[3],
        ].forEach((order, idx, list) => {
          // Compare each invocation sequence to the one before it (except the first one)
          expect(list[idx - 1] || -1).toBeLessThan(order);
        });
      });
    });
  });
});
