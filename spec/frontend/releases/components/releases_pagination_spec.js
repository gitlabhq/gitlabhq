import { mountExtended } from 'helpers/vue_test_utils_helper';
import { historyPushState } from '~/lib/utils/common_utils';
import ReleasesPagination from '~/releases/components/releases_pagination.vue';

jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  historyPushState: jest.fn(),
}));

describe('releases_pagination.vue', () => {
  const startCursor = 'startCursor';
  const endCursor = 'endCursor';
  let wrapper;
  let onPrev;
  let onNext;

  const createComponent = (pageInfo) => {
    onPrev = jest.fn();
    onNext = jest.fn();

    wrapper = mountExtended(ReleasesPagination, {
      propsData: {
        pageInfo,
      },
      listeners: {
        prev: onPrev,
        next: onNext,
      },
    });
  };

  const singlePageInfo = {
    hasPreviousPage: false,
    hasNextPage: false,
    startCursor,
    endCursor,
  };

  const onlyNextPageInfo = {
    hasPreviousPage: false,
    hasNextPage: true,
    startCursor,
    endCursor,
  };

  const onlyPrevPageInfo = {
    hasPreviousPage: true,
    hasNextPage: false,
    startCursor,
    endCursor,
  };

  const prevAndNextPageInfo = {
    hasPreviousPage: true,
    hasNextPage: true,
    startCursor,
    endCursor,
  };

  const findPrevButton = () => wrapper.findByTestId('prevButton');
  const findNextButton = () => wrapper.findByTestId('nextButton');

  describe('when there is only one page of results', () => {
    beforeEach(() => {
      createComponent(singlePageInfo);
    });

    it('hides the "Prev" button', () => {
      expect(findPrevButton().exists()).toBe(false);
    });

    it('hides the "Next" button', () => {
      expect(findNextButton().exists()).toBe(false);
    });
  });

  describe.each`
    description                                             | pageInfo               | prevEnabled | nextEnabled
    ${'when there is a next page, but not a previous page'} | ${onlyNextPageInfo}    | ${false}    | ${true}
    ${'when there is a previous page, but not a next page'} | ${onlyPrevPageInfo}    | ${true}     | ${false}
    ${'when there is both a previous and next page'}        | ${prevAndNextPageInfo} | ${true}     | ${true}
  `('component states', ({ description, pageInfo, prevEnabled, nextEnabled }) => {
    describe(description, () => {
      beforeEach(() => {
        createComponent(pageInfo);
      });

      it(`renders the "Prev" button as ${prevEnabled ? 'enabled' : 'disabled'}`, () => {
        expect(findPrevButton().attributes().disabled).toBe(prevEnabled ? undefined : 'disabled');
      });

      it(`renders the "Next" button as ${nextEnabled ? 'enabled' : 'disabled'}`, () => {
        expect(findNextButton().attributes().disabled).toBe(nextEnabled ? undefined : 'disabled');
      });
    });
  });

  describe('button behavior', () => {
    beforeEach(() => {
      createComponent(prevAndNextPageInfo);
    });

    describe('next button behavior', () => {
      beforeEach(() => {
        findNextButton().trigger('click');
      });

      it('emits an "next" event with the "after" cursor', () => {
        expect(onNext.mock.calls).toEqual([[endCursor]]);
      });

      it('calls historyPushState with the new URL', () => {
        expect(historyPushState.mock.calls).toEqual([
          [expect.stringContaining(`?after=${endCursor}`)],
        ]);
      });
    });

    describe('prev button behavior', () => {
      beforeEach(() => {
        findPrevButton().trigger('click');
      });

      it('emits an "prev" event with the "before" cursor', () => {
        expect(onPrev.mock.calls).toEqual([[startCursor]]);
      });

      it('calls historyPushState with the new URL', () => {
        expect(historyPushState.mock.calls).toEqual([
          [expect.stringContaining(`?before=${startCursor}`)],
        ]);
      });
    });
  });
});
