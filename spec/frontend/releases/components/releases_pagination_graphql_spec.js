import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import createStore from '~/releases/stores';
import createListModule from '~/releases/stores/modules/list';
import ReleasesPaginationGraphql from '~/releases/components/releases_pagination_graphql.vue';
import { historyPushState } from '~/lib/utils/common_utils';

jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  historyPushState: jest.fn(),
}));

const localVue = createLocalVue();
localVue.use(Vuex);

describe('~/releases/components/releases_pagination_graphql.vue', () => {
  let wrapper;
  let listModule;

  const cursors = {
    startCursor: 'startCursor',
    endCursor: 'endCursor',
  };

  const projectPath = 'my/project';

  const createComponent = pageInfo => {
    listModule = createListModule({ projectPath });

    listModule.state.graphQlPageInfo = pageInfo;

    listModule.actions.fetchReleases = jest.fn();

    wrapper = mount(ReleasesPaginationGraphql, {
      store: createStore({
        modules: {
          list: listModule,
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

  const findPrevButton = () => wrapper.find('[data-testid="prevButton"]');
  const findNextButton = () => wrapper.find('[data-testid="nextButton"]');

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

    it('does not render anything', () => {
      expect(wrapper.isEmpty()).toBe(true);
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
        expect(listModule.actions.fetchReleases.mock.calls).toEqual([
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
        expect(listModule.actions.fetchReleases.mock.calls).toEqual([
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
