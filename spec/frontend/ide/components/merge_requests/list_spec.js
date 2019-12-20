import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import List from '~/ide/components/merge_requests/list.vue';
import Item from '~/ide/components/merge_requests/item.vue';
import TokenedInput from '~/ide/components/shared/tokened_input.vue';
import { mergeRequests as mergeRequestsMock } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('IDE merge requests list', () => {
  let wrapper;
  let fetchMergeRequestsMock;

  const findSearchTypeButtons = () => wrapper.findAll('button');
  const findTokenedInput = () => wrapper.find(TokenedInput);

  const createComponent = (state = {}) => {
    const { mergeRequests = {}, ...restOfState } = state;
    const fakeStore = new Vuex.Store({
      state: {
        currentMergeRequestId: '1',
        currentProjectId: 'project/master',
        ...restOfState,
      },
      modules: {
        mergeRequests: {
          namespaced: true,
          state: {
            isLoading: false,
            mergeRequests: [],
            ...mergeRequests,
          },
          actions: {
            fetchMergeRequests: fetchMergeRequestsMock,
          },
        },
      },
    });

    wrapper = shallowMount(List, {
      store: fakeStore,
      localVue,
      sync: false,
    });
  };

  beforeEach(() => {
    fetchMergeRequestsMock = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('calls fetch on mounted', () => {
    createComponent();
    expect(fetchMergeRequestsMock).toHaveBeenCalledWith(
      expect.any(Object),
      {
        search: '',
        type: '',
      },
      undefined,
    );
  });

  it('renders loading icon when merge request is loading', () => {
    createComponent({ mergeRequests: { isLoading: true } });
    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('renders no search results text when search is not empty', () => {
    createComponent();
    findTokenedInput().vm.$emit('input', 'something');
    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.text()).toContain('No merge requests found');
    });
  });

  it('clicking on search type, sets currentSearchType and loads merge requests', () => {
    createComponent();
    findTokenedInput().vm.$emit('focus');

    return wrapper.vm
      .$nextTick()
      .then(() => {
        findSearchTypeButtons()
          .at(0)
          .trigger('click');
        return wrapper.vm.$nextTick();
      })
      .then(() => {
        const searchType = wrapper.vm.$options.searchTypes[0];

        expect(findTokenedInput().props('tokens')).toEqual([searchType]);
        expect(fetchMergeRequestsMock).toHaveBeenCalledWith(
          expect.any(Object),
          {
            type: searchType.type,
            search: '',
          },
          undefined,
        );
      });
  });

  describe('with merge requests', () => {
    let defaultStateWithMergeRequests;

    beforeAll(() => {
      defaultStateWithMergeRequests = {
        mergeRequests: {
          isLoading: false,
          mergeRequests: [
            { ...mergeRequestsMock[0], projectPathWithNamespace: 'gitlab-org/gitlab-foss' },
          ],
        },
      };
    });

    it('renders list', () => {
      createComponent(defaultStateWithMergeRequests);

      expect(wrapper.findAll(Item).length).toBe(1);
      expect(wrapper.find(Item).props('item')).toBe(
        defaultStateWithMergeRequests.mergeRequests.mergeRequests[0],
      );
    });

    describe('when searching merge requests', () => {
      it('calls `loadMergeRequests` on input in search field', () => {
        createComponent(defaultStateWithMergeRequests);
        const input = findTokenedInput();
        input.vm.$emit('input', 'something');
        fetchMergeRequestsMock.mockClear();

        jest.runAllTimers();
        return wrapper.vm.$nextTick().then(() => {
          expect(fetchMergeRequestsMock).toHaveBeenCalledWith(
            expect.any(Object),
            {
              search: 'something',
              type: '',
            },
            undefined,
          );
        });
      });
    });
  });

  describe('on search focus', () => {
    let input;

    beforeEach(() => {
      createComponent();
      input = findTokenedInput();
    });

    describe('without search value', () => {
      beforeEach(() => {
        input.vm.$emit('focus');
        return wrapper.vm.$nextTick();
      });

      it('shows search types', () => {
        const buttons = findSearchTypeButtons();
        expect(buttons.wrappers.map(x => x.text().trim())).toEqual(
          wrapper.vm.$options.searchTypes.map(x => x.label),
        );
      });

      it('hides search types when search changes', () => {
        input.vm.$emit('input', 'something');

        return wrapper.vm.$nextTick().then(() => {
          expect(findSearchTypeButtons().exists()).toBe(false);
        });
      });

      describe('with search type', () => {
        beforeEach(() => {
          findSearchTypeButtons()
            .at(0)
            .trigger('click');

          return wrapper.vm
            .$nextTick()
            .then(() => input.vm.$emit('focus'))
            .then(() => wrapper.vm.$nextTick());
        });

        it('does not show search types', () => {
          expect(findSearchTypeButtons().exists()).toBe(false);
        });
      });
    });

    describe('with search value', () => {
      beforeEach(() => {
        input.vm.$emit('input', 'something');
        input.vm.$emit('focus');
        return wrapper.vm.$nextTick();
      });

      it('does not show search types', () => {
        expect(findSearchTypeButtons().exists()).toBe(false);
      });
    });
  });
});
