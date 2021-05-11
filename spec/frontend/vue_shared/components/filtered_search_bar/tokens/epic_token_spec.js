import { GlFilteredSearchToken, GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

import EpicToken from '~/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';

import { mockEpicToken, mockEpics } from '../mock_data';

jest.mock('~/flash');

const defaultStubs = {
  Portal: true,
  GlFilteredSearchSuggestionList: {
    template: '<div></div>',
    methods: {
      getValue: () => '=',
    },
  },
};

function createComponent(options = {}) {
  const {
    config = mockEpicToken,
    value = { data: '' },
    active = false,
    stubs = defaultStubs,
  } = options;
  return mount(EpicToken, {
    propsData: {
      config,
      value,
      active,
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
      suggestionsListClass: 'custom-class',
    },
    stubs,
  });
}

describe('EpicToken', () => {
  let mock;
  let wrapper;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    wrapper = createComponent();
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  describe('computed', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        data: {
          epics: mockEpics,
        },
      });

      await wrapper.vm.$nextTick();
    });

    describe('activeEpic', () => {
      it('returns object for currently present `value.data`', async () => {
        wrapper.setProps({
          value: { data: `${mockEpics[0].iid}` },
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.activeEpic).toEqual(mockEpics[0]);
      });
    });
  });

  describe('methods', () => {
    describe('fetchEpicsBySearchTerm', () => {
      it('calls `config.fetchEpics` with provided searchTerm param', () => {
        jest.spyOn(wrapper.vm.config, 'fetchEpics');

        wrapper.vm.fetchEpicsBySearchTerm('foo');

        expect(wrapper.vm.config.fetchEpics).toHaveBeenCalledWith('foo');
      });

      it('sets response to `epics` when request is successful', async () => {
        jest.spyOn(wrapper.vm.config, 'fetchEpics').mockResolvedValue({
          data: mockEpics,
        });

        wrapper.vm.fetchEpicsBySearchTerm();

        await waitForPromises();

        expect(wrapper.vm.epics).toEqual(mockEpics);
      });

      it('calls `createFlash` with flash error message when request fails', async () => {
        jest.spyOn(wrapper.vm.config, 'fetchEpics').mockRejectedValue({});

        wrapper.vm.fetchEpicsBySearchTerm('foo');

        await waitForPromises();

        expect(createFlash).toHaveBeenCalledWith({
          message: 'There was a problem fetching epics.',
        });
      });

      it('sets `loading` to false when request completes', async () => {
        jest.spyOn(wrapper.vm.config, 'fetchEpics').mockRejectedValue({});

        wrapper.vm.fetchEpicsBySearchTerm('foo');

        await waitForPromises();

        expect(wrapper.vm.loading).toBe(false);
      });
    });
  });

  describe('template', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        value: { data: `${mockEpics[0].iid}` },
        data: { epics: mockEpics },
      });

      await wrapper.vm.$nextTick();
    });

    it('renders gl-filtered-search-token component', () => {
      expect(wrapper.find(GlFilteredSearchToken).exists()).toBe(true);
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3);
      expect(tokenSegments.at(2).text()).toBe(`${mockEpics[0].title}::&${mockEpics[0].iid}`);
    });
  });
});
