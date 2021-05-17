import { GlKeysetPagination } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { historyPushState } from '~/lib/utils/common_utils';
import ReleasesPagination from '~/releases/components/releases_pagination.vue';
import createStore from '~/releases/stores';
import createIndexModule from '~/releases/stores/modules/index';

jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  historyPushState: jest.fn(),
}));

const localVue = createLocalVue();
localVue.use(Vuex);

describe('~/releases/components/releases_pagination.vue', () => {
  let wrapper;
  let indexModule;

  const cursors = {
    startCursor: 'startCursor',
    endCursor: 'endCursor',
  };

  const projectPath = 'my/project';

  const createComponent = (pageInfo) => {
    indexModule = createIndexModule({ projectPath });

    indexModule.state.pageInfo = pageInfo;

    indexModule.actions.fetchReleases = jest.fn();

    wrapper = mount(ReleasesPagination, {
      store: createStore({
        modules: {
          index: indexModule,
        },
        featureFlags: {},
      }),
      localVue,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findGlKeysetPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findPrevButton = () => findGlKeysetPagination().find('[data-testid="prevButton"]');
  const findNextButton = () => findGlKeysetPagination().find('[data-testid="nextButton"]');

  const expectDisabledPrev = () => {
    expect(findPrevButton().attributes().disabled).toBe('disabled');
  };
  const expectEnabledPrev = () => {
    expect(findPrevButton().attributes().disabled).toBe(undefined);
  };
  const expectDisabledNext = () => {
    expect(findNextButton().attributes().disabled).toBe('disabled');
  };
  const expectEnabledNext = () => {
    expect(findNextButton().attributes().disabled).toBe(undefined);
  };

  describe('when there is only one page of results', () => {
    beforeEach(() => {
      createComponent({
        hasPreviousPage: false,
        hasNextPage: false,
      });
    });

    it('does not render a GlKeysetPagination', () => {
      expect(findGlKeysetPagination().exists()).toBe(false);
    });
  });

  describe('when there is a next page, but not a previous page', () => {
    beforeEach(() => {
      createComponent({
        hasPreviousPage: false,
        hasNextPage: true,
      });
    });

    it('renders a disabled "Prev" button', () => {
      expectDisabledPrev();
    });

    it('renders an enabled "Next" button', () => {
      expectEnabledNext();
    });
  });

  describe('when there is a previous page, but not a next page', () => {
    beforeEach(() => {
      createComponent({
        hasPreviousPage: true,
        hasNextPage: false,
      });
    });

    it('renders a enabled "Prev" button', () => {
      expectEnabledPrev();
    });

    it('renders an disabled "Next" button', () => {
      expectDisabledNext();
    });
  });

  describe('when there is both a previous page and a next page', () => {
    beforeEach(() => {
      createComponent({
        hasPreviousPage: true,
        hasNextPage: true,
      });
    });

    it('renders a enabled "Prev" button', () => {
      expectEnabledPrev();
    });

    it('renders an enabled "Next" button', () => {
      expectEnabledNext();
    });
  });

  describe('button behavior', () => {
    beforeEach(() => {
      createComponent({
        hasPreviousPage: true,
        hasNextPage: true,
        ...cursors,
      });
    });

    describe('next button behavior', () => {
      beforeEach(() => {
        findNextButton().trigger('click');
      });

      it('calls fetchReleases with the correct after cursor', () => {
        expect(indexModule.actions.fetchReleases.mock.calls).toEqual([
          [expect.anything(), { after: cursors.endCursor }],
        ]);
      });

      it('calls historyPushState with the new URL', () => {
        expect(historyPushState.mock.calls).toEqual([
          [expect.stringContaining(`?after=${cursors.endCursor}`)],
        ]);
      });
    });

    describe('previous button behavior', () => {
      beforeEach(() => {
        findPrevButton().trigger('click');
      });

      it('calls fetchReleases with the correct before cursor', () => {
        expect(indexModule.actions.fetchReleases.mock.calls).toEqual([
          [expect.anything(), { before: cursors.startCursor }],
        ]);
      });

      it('calls historyPushState with the new URL', () => {
        expect(historyPushState.mock.calls).toEqual([
          [expect.stringContaining(`?before=${cursors.startCursor}`)],
        ]);
      });
    });
  });
});
