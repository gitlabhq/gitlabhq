import { mount } from '@vue/test-utils';
import { GlFilteredSearchToken, GlFilteredSearchTokenSegment } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';

import createFlash from '~/flash';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';

import { mockAuthorToken, mockAuthors } from '../mock_data';

jest.mock('~/flash');

const createComponent = ({ config = mockAuthorToken, value = { data: '' } } = {}) =>
  mount(AuthorToken, {
    propsData: {
      config,
      value,
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
    },
    stubs: {
      Portal: {
        template: '<div><slot></slot></div>',
      },
      GlFilteredSearchSuggestionList: {
        template: '<div></div>',
        methods: {
          getValue: () => '=',
        },
      },
    },
  });

describe('AuthorToken', () => {
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
    describe('currentValue', () => {
      it('returns lowercase string for `value.data`', () => {
        wrapper.setProps({
          value: { data: 'FOO' },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.currentValue).toBe('foo');
        });
      });
    });

    describe('activeAuthor', () => {
      it('returns object for currently present `value.data`', () => {
        wrapper.setData({
          authors: mockAuthors,
        });

        wrapper.setProps({
          value: { data: mockAuthors[0].username },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.activeAuthor).toEqual(mockAuthors[0]);
        });
      });
    });
  });

  describe('fetchAuthorBySearchTerm', () => {
    it('calls `config.fetchAuthors` with provided searchTerm param', () => {
      jest.spyOn(wrapper.vm.config, 'fetchAuthors');

      wrapper.vm.fetchAuthorBySearchTerm(mockAuthors[0].username);

      expect(wrapper.vm.config.fetchAuthors).toHaveBeenCalledWith(
        mockAuthorToken.fetchPath,
        mockAuthors[0].username,
      );
    });

    it('sets response to `authors` when request is succesful', () => {
      jest.spyOn(wrapper.vm.config, 'fetchAuthors').mockResolvedValue(mockAuthors);

      wrapper.vm.fetchAuthorBySearchTerm('root');

      return waitForPromises().then(() => {
        expect(wrapper.vm.authors).toEqual(mockAuthors);
      });
    });

    it('calls `createFlash` with flash error message when request fails', () => {
      jest.spyOn(wrapper.vm.config, 'fetchAuthors').mockRejectedValue({});

      wrapper.vm.fetchAuthorBySearchTerm('root');

      return waitForPromises().then(() => {
        expect(createFlash).toHaveBeenCalledWith('There was a problem fetching users.');
      });
    });

    it('sets `loading` to false when request completes', () => {
      jest.spyOn(wrapper.vm.config, 'fetchAuthors').mockRejectedValue({});

      wrapper.vm.fetchAuthorBySearchTerm('root');

      return waitForPromises().then(() => {
        expect(wrapper.vm.loading).toBe(false);
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      wrapper.setData({
        authors: mockAuthors,
      });

      return wrapper.vm.$nextTick();
    });

    it('renders gl-filtered-search-token component', () => {
      expect(wrapper.find(GlFilteredSearchToken).exists()).toBe(true);
    });

    it('renders token item when value is selected', () => {
      wrapper.setProps({
        value: { data: mockAuthors[0].username },
      });

      return wrapper.vm.$nextTick(() => {
        const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);

        expect(tokenSegments).toHaveLength(3); // Author, =, "Administrator"
        expect(tokenSegments.at(2).text()).toBe(mockAuthors[0].name); // "Administrator"
      });
    });
  });
});
