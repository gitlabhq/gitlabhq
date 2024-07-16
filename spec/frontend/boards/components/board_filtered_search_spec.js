import { shallowMount } from '@vue/test-utils';
import BoardFilteredSearch from '~/boards/components/board_filtered_search.vue';
import { updateHistory } from '~/lib/utils/url_utility';
import {
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_HEALTH,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_WEIGHT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBarRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  updateHistory: jest.fn(),
  setUrlParams: jest.requireActual('~/lib/utils/url_utility').setUrlParams,
  queryToObject: jest.requireActual('~/lib/utils/url_utility').queryToObject,
}));

describe('BoardFilteredSearch', () => {
  let wrapper;
  const tokens = [
    {
      icon: 'labels',
      title: TOKEN_TITLE_LABEL,
      type: TOKEN_TYPE_LABEL,
      operators: [
        { value: '=', description: 'is' },
        { value: '!=', description: 'is not' },
      ],
      token: LabelToken,
      unique: false,
      symbol: '~',
      fetchLabels: () => new Promise(() => {}),
    },
    {
      icon: 'pencil',
      title: TOKEN_TITLE_AUTHOR,
      type: TOKEN_TYPE_AUTHOR,
      operators: [
        { value: '=', description: 'is' },
        { value: '!=', description: 'is not' },
      ],
      symbol: '@',
      token: UserToken,
      unique: true,
      fetchUsers: () => new Promise(() => {}),
    },
  ];

  const createComponent = ({ initialFilterParams = {}, props = {}, provide = {} } = {}) => {
    wrapper = shallowMount(BoardFilteredSearch, {
      provide: {
        initialFilterParams,
        fullPath: '',
        ...provide,
      },
      propsData: {
        ...props,
        tokens,
        filters: {},
      },
    });
  };

  const findFilteredSearch = () => wrapper.findComponent(FilteredSearchBarRoot);

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes the correct tokens to FilteredSearch', () => {
      expect(findFilteredSearch().props('tokens')).toEqual(tokens);
    });

    describe('when onFilter is emitted', () => {
      it('calls historyPushState', () => {
        findFilteredSearch().vm.$emit('onFilter', [{ value: { data: 'searchQuery' } }]);

        expect(updateHistory).toHaveBeenCalledWith({
          replace: true,
          title: '',
          url: 'http://test.host/',
        });
      });
    });

    it('emits setFilters and updates URL when onFilter is emitted', () => {
      findFilteredSearch().vm.$emit('onFilter', [{ value: { data: '' } }]);

      expect(updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url: 'http://test.host/',
      });

      expect(wrapper.emitted('setFilters')).toHaveLength(1);
    });
  });

  describe('when eeFilters is not empty', () => {
    it('passes the correct initialFilterValue to FilteredSearchBarRoot', () => {
      createComponent({ props: { eeFilters: { labelName: ['label'] } } });

      expect(findFilteredSearch().props('initialFilterValue')).toEqual([
        { type: TOKEN_TYPE_LABEL, value: { data: 'label', operator: '=' } },
      ]);
    });
  });

  it('renders FilteredSearch', () => {
    createComponent();

    expect(findFilteredSearch().exists()).toBe(true);
  });

  describe('when searching', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets the url params to the correct results', () => {
      const mockFilters = [
        { type: TOKEN_TYPE_AUTHOR, value: { data: 'root', operator: '=' } },
        { type: TOKEN_TYPE_ASSIGNEE, value: { data: 'root', operator: '=' } },
        { type: TOKEN_TYPE_LABEL, value: { data: 'label', operator: '=' } },
        { type: TOKEN_TYPE_LABEL, value: { data: 'label&2', operator: '=' } },
        { type: TOKEN_TYPE_MILESTONE, value: { data: 'New Milestone', operator: '=' } },
        { type: TOKEN_TYPE_TYPE, value: { data: 'INCIDENT', operator: '=' } },
        { type: TOKEN_TYPE_WEIGHT, value: { data: '2', operator: '=' } },
        { type: TOKEN_TYPE_ITERATION, value: { data: 'Any&3', operator: '=' } },
        { type: TOKEN_TYPE_RELEASE, value: { data: 'v1.0.0', operator: '=' } },
        { type: TOKEN_TYPE_HEALTH, value: { data: 'onTrack', operator: '=' } },
        { type: TOKEN_TYPE_HEALTH, value: { data: 'atRisk', operator: '!=' } },
      ];

      findFilteredSearch().vm.$emit('onFilter', mockFilters);

      expect(updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url: 'http://test.host/?not[health_status]=atRisk&author_username=root&label_name[]=label&label_name[]=label%262&assignee_username=root&milestone_title=New%20Milestone&iteration_id=Any&iteration_cadence_id=3&types=INCIDENT&weight=2&release_tag=v1.0.0&health_status=onTrack',
      });
    });

    describe('when assignee is passed a wildcard value', () => {
      const url = (arg) => `http://test.host/?assignee_id=${arg}`;

      it.each([
        ['None', url('None')],
        ['Any', url('Any')],
      ])('sets the url param %s', (assigneeParam, expected) => {
        const mockFilters = [
          { type: TOKEN_TYPE_ASSIGNEE, value: { data: assigneeParam, operator: '=' } },
        ];

        findFilteredSearch().vm.$emit('onFilter', mockFilters);

        expect(updateHistory).toHaveBeenCalledWith({
          title: '',
          replace: true,
          url: expected,
        });
      });
    });
  });

  describe('when url params are already set', () => {
    beforeEach(() => {
      createComponent({
        initialFilterParams: { authorUsername: 'root', labelName: ['label'], healthStatus: 'Any' },
      });
    });

    it('passes the correct props to FilterSearchBar', () => {
      expect(findFilteredSearch().props('initialFilterValue')).toEqual([
        { type: TOKEN_TYPE_AUTHOR, value: { data: 'root', operator: '=' } },
        { type: TOKEN_TYPE_LABEL, value: { data: 'label', operator: '=' } },
        { type: TOKEN_TYPE_HEALTH, value: { data: 'Any', operator: '=' } },
      ]);
    });
  });

  describe('when iteration is passed a wildcard value with a cadence id', () => {
    const url = (arg) => `http://test.host/?iteration_id=${arg}&iteration_cadence_id=1349`;

    beforeEach(() => {
      createComponent();
    });

    it.each([
      ['Current&1349', url('Current'), 'Current'],
      ['Any&1349', url('Any'), 'Any'],
    ])('sets the url param %s', (iterationParam, expected, wildCardId) => {
      Object.defineProperty(window, 'location', {
        writable: true,
        value: new URL(expected),
      });

      const mockFilters = [
        { type: TOKEN_TYPE_ITERATION, value: { data: iterationParam, operator: '=' } },
      ];

      findFilteredSearch().vm.$emit('onFilter', mockFilters);

      expect(updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url: expected,
      });

      expect(wrapper.emitted('setFilters')).toStrictEqual([
        [
          {
            iterationCadenceId: '1349',
            iterationId: wildCardId,
          },
        ],
      ]);
    });
  });
});
