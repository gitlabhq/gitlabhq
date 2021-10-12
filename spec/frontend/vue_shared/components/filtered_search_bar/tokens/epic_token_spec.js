import { GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

import searchEpicsQuery from '~/vue_shared/components/filtered_search_bar/queries/search_epics.query.graphql';
import EpicToken from '~/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

import { mockEpicToken, mockEpics, mockGroupEpicsQueryResponse } from '../mock_data';

jest.mock('~/flash');
Vue.use(VueApollo);

const defaultStubs = {
  Portal: true,
  GlFilteredSearchSuggestionList: {
    template: '<div></div>',
    methods: {
      getValue: () => '=',
    },
  },
};

describe('EpicToken', () => {
  let mock;
  let wrapper;
  let fakeApollo;

  const findBaseToken = () => wrapper.findComponent(BaseToken);

  function createComponent(
    options = {},
    epicsQueryHandler = jest.fn().mockResolvedValue(mockGroupEpicsQueryResponse),
  ) {
    fakeApollo = createMockApollo([[searchEpicsQuery, epicsQueryHandler]]);
    const {
      config = mockEpicToken,
      value = { data: '' },
      active = false,
      stubs = defaultStubs,
    } = options;
    return mount(EpicToken, {
      apolloProvider: fakeApollo,
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
  });

  describe('methods', () => {
    describe('fetchEpicsBySearchTerm', () => {
      it('calls fetchEpics with provided searchTerm param', () => {
        jest.spyOn(wrapper.vm, 'fetchEpics');

        findBaseToken().vm.$emit('fetch-suggestions', 'foo');

        expect(wrapper.vm.fetchEpics).toHaveBeenCalledWith('foo');
      });

      it('sets response to `epics` when request is successful', async () => {
        jest.spyOn(wrapper.vm, 'fetchEpics').mockResolvedValue({
          data: mockEpics,
        });

        findBaseToken().vm.$emit('fetch-suggestions');

        await waitForPromises();

        expect(wrapper.vm.epics).toEqual(mockEpics);
      });

      it('calls `createFlash` with flash error message when request fails', async () => {
        jest.spyOn(wrapper.vm, 'fetchEpics').mockRejectedValue({});

        findBaseToken().vm.$emit('fetch-suggestions', 'foo');

        await waitForPromises();

        expect(createFlash).toHaveBeenCalledWith({
          message: 'There was a problem fetching epics.',
        });
      });

      it('sets `loading` to false when request completes', async () => {
        jest.spyOn(wrapper.vm, 'fetchEpics').mockRejectedValue({});

        findBaseToken().vm.$emit('fetch-suggestions', 'foo');

        await waitForPromises();

        expect(wrapper.vm.loading).toBe(false);
      });
    });
  });

  describe('template', () => {
    const getTokenValueEl = () => wrapper.findAllComponents(GlFilteredSearchTokenSegment).at(2);

    beforeEach(async () => {
      wrapper = createComponent({
        value: { data: `${mockEpics[0].title}::&${mockEpics[0].iid}` },
        data: { epics: mockEpics },
      });

      await wrapper.vm.$nextTick();
    });

    it('renders BaseToken component', () => {
      expect(findBaseToken().exists()).toBe(true);
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3);
      expect(tokenSegments.at(2).text()).toBe(`${mockEpics[0].title}::&${mockEpics[0].iid}`);
    });

    it.each`
      value                                            | valueType   | tokenValueString
      ${`${mockEpics[0].title}::&${mockEpics[0].iid}`} | ${'string'} | ${`${mockEpics[0].title}::&${mockEpics[0].iid}`}
      ${`${mockEpics[1].title}::&${mockEpics[1].iid}`} | ${'number'} | ${`${mockEpics[1].title}::&${mockEpics[1].iid}`}
    `('renders token item when selection is a $valueType', async ({ value, tokenValueString }) => {
      wrapper.setProps({
        value: { data: value },
      });

      await wrapper.vm.$nextTick();

      expect(getTokenValueEl().text()).toBe(tokenValueString);
    });
  });
});
