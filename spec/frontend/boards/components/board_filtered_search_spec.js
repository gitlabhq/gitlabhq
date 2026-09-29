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
        hasCustomFieldsFeature: false,
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

    it('shows friendly operator text so the description is left and the symbol is right', () => {
      expect(findFilteredSearch().props('showFriendlyText')).toBe(true);
    });

    describe('when on-filter is emitted', () => {
      it('calls historyPushState', () => {
        findFilteredSearch().vm.$emit('on-filter', [{ value: { data: 'searchQuery' } }]);

        expect(updateHistory).toHaveBeenCalledWith({
          replace: true,
          title: '',
          url: 'http://test.host/',
        });
      });
    });

    it('emits set-filters and updates URL when on-filter is emitted', () => {
      findFilteredSearch().vm.$emit('on-filter', [{ value: { data: '' } }]);

      expect(updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url: 'http://test.host/',
      });

      expect(wrapper.emitted('set-filters')).toHaveLength(1);
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

      findFilteredSearch().vm.$emit('on-filter', mockFilters);

      expect(updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url: 'http://test.host/?not[health_status]=atRisk&type%5B%5D=INCIDENT&author_username=root&label_name[]=label&label_name[]=label%262&assignee_username=root&milestone_title=New%20Milestone&iteration_id=Any&iteration_cadence_id=3&weight=2&release_tag=v1.0.0&health_status=onTrack',
      });
    });

    it('sets the url params for multi-value NOT (is not one of) filters', () => {
      const mockFilters = [
        { type: TOKEN_TYPE_AUTHOR, value: { data: ['root', 'admin'], operator: '!=' } },
        { type: TOKEN_TYPE_ASSIGNEE, value: { data: ['root', 'admin'], operator: '!=' } },
        { type: TOKEN_TYPE_TYPE, value: { data: ['INCIDENT', 'ISSUE'], operator: '!=' } },
      ];

      findFilteredSearch().vm.$emit('on-filter', mockFilters);

      expect(updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url: 'http://test.host/?not[author_usernames][]=root&not[author_usernames][]=admin&not[assignee_username][]=root&not[assignee_username][]=admin&not[type][]=INCIDENT&not[type][]=ISSUE',
      });

      expect(wrapper.emitted('set-filters')).toHaveLength(1);
    });

    it('sets the url params for OR (is one of) filters', () => {
      const mockFilters = [
        { type: TOKEN_TYPE_AUTHOR, value: { data: ['root', 'admin'], operator: '||' } },
        { type: TOKEN_TYPE_ASSIGNEE, value: { data: ['root', 'admin'], operator: '||' } },
        { type: TOKEN_TYPE_LABEL, value: { data: ['bug', 'feature'], operator: '||' } },
      ];

      findFilteredSearch().vm.$emit('on-filter', mockFilters);

      expect(updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url: 'http://test.host/?or%5Blabel_name%5D%5B%5D=bug&or%5Blabel_name%5D%5B%5D=feature&or%5Bauthor_username%5D%5B%5D=root&or%5Bauthor_username%5D%5B%5D=admin&or%5Bassignee_username%5D%5B%5D=root&or%5Bassignee_username%5D%5B%5D=admin',
      });

      expect(wrapper.emitted('set-filters')).toHaveLength(1);
    });

    it('serializes a type "is one of" (OR) filter as an encoded array of type[]', () => {
      const mockFilters = [
        { type: TOKEN_TYPE_TYPE, value: { data: ['INCIDENT', 'ISSUE'], operator: '||' } },
      ];

      findFilteredSearch().vm.$emit('on-filter', mockFilters);

      expect(updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url: 'http://test.host/?type%5B%5D=INCIDENT&type%5B%5D=ISSUE',
      });

      expect(wrapper.emitted('set-filters')).toHaveLength(1);
    });

    describe('when assignee is passed a wildcard value', () => {
      const url = (arg) => `http://test.host/?assignee_id=${arg}`;

      it.each([
        ['None', url('None')],
        ['Any', url('Any')],
        ['Me', url('Me')],
      ])('sets the url param %s', (assigneeParam, expected) => {
        const mockFilters = [
          { type: TOKEN_TYPE_ASSIGNEE, value: { data: assigneeParam, operator: '=' } },
        ];

        findFilteredSearch().vm.$emit('on-filter', mockFilters);

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

  describe('when OR (is one of) url params are already set', () => {
    beforeEach(() => {
      createComponent({
        initialFilterParams: {
          'or[authorUsername]': ['root', 'admin'],
          'or[assigneeUsername]': ['root', 'admin'],
          'or[labelName]': ['bug', 'feature'],
        },
      });
    });

    it('passes the correct OR tokens to FilterSearchBar', () => {
      expect(findFilteredSearch().props('initialFilterValue')).toEqual([
        { type: TOKEN_TYPE_AUTHOR, value: { data: ['root', 'admin'], operator: '||' } },
        { type: TOKEN_TYPE_ASSIGNEE, value: { data: ['root', 'admin'], operator: '||' } },
        { type: TOKEN_TYPE_LABEL, value: { data: ['bug', 'feature'], operator: '||' } },
      ]);
    });
  });

  describe('when multi-value NOT (is not one of) url params are already set', () => {
    beforeEach(() => {
      createComponent({
        initialFilterParams: {
          'not[authorUsernames]': ['root', 'admin'],
          'not[assigneeUsername]': ['root', 'admin'],
        },
      });
    });

    it('passes a single NOT token with an array of values to FilterSearchBar', () => {
      expect(findFilteredSearch().props('initialFilterValue')).toEqual([
        { type: TOKEN_TYPE_AUTHOR, value: { data: ['root', 'admin'], operator: '!=' } },
        { type: TOKEN_TYPE_ASSIGNEE, value: { data: ['root', 'admin'], operator: '!=' } },
      ]);
    });
  });

  describe('when NOT label url params are already set', () => {
    beforeEach(() => {
      createComponent({
        initialFilterParams: {
          'not[labelName]': ['bug', 'feature'],
        },
      });
    });

    it('passes a single multi-value NOT label token to FilterSearchBar', () => {
      expect(findFilteredSearch().props('initialFilterValue')).toEqual([
        { type: TOKEN_TYPE_LABEL, value: { data: ['bug', 'feature'], operator: '!=' } },
      ]);
    });
  });

  describe('when a legacy scalar NOT param is already set', () => {
    beforeEach(() => {
      createComponent({
        initialFilterParams: {
          'not[authorUsername]': 'root',
          'not[assigneeUsername]': 'root',
          'not[labelName]': 'bug',
        },
      });
    });

    it('still hydrates old bookmarked NOT URLs into a single token', () => {
      expect(findFilteredSearch().props('initialFilterValue')).toEqual([
        { type: TOKEN_TYPE_AUTHOR, value: { data: 'root', operator: '!=' } },
        { type: TOKEN_TYPE_ASSIGNEE, value: { data: 'root', operator: '!=' } },
        { type: TOKEN_TYPE_LABEL, value: { data: 'bug', operator: '!=' } },
      ]);
    });
  });

  describe('when a multi-value type param is already set', () => {
    beforeEach(() => {
      createComponent({
        initialFilterParams: { type: ['INCIDENT', 'ISSUE'] },
      });
    });

    it('passes a single type "is one of" (OR) token to FilterSearchBar', () => {
      expect(findFilteredSearch().props('initialFilterValue')).toEqual([
        { type: TOKEN_TYPE_TYPE, value: { data: ['INCIDENT', 'ISSUE'], operator: '||' } },
      ]);
    });
  });

  describe('when a legacy `types` param is already set', () => {
    beforeEach(() => {
      createComponent({
        initialFilterParams: { types: 'INCIDENT' },
      });
    });

    it('falls back to the legacy param and passes an "is" token to FilterSearchBar', () => {
      expect(findFilteredSearch().props('initialFilterValue')).toEqual([
        { type: TOKEN_TYPE_TYPE, value: { data: 'INCIDENT', operator: '=' } },
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

      findFilteredSearch().vm.$emit('on-filter', mockFilters);

      expect(updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url: expected,
      });

      expect(wrapper.emitted('set-filters')).toStrictEqual([
        [
          {
            iterationCadenceId: '1349',
            iterationId: wildCardId,
          },
        ],
      ]);
    });
  });

  describe('custom fields enabled', () => {
    beforeEach(() => {
      createComponent({
        initialFilterParams: {
          'custom-field[1]': '2',
        },
        provide: {
          hasCustomFieldsFeature: true,
        },
      });
    });

    it('passes the correct props to FilterSearchBar', () => {
      expect(findFilteredSearch().props('initialFilterValue')).toEqual([
        { type: 'custom-field[1]', value: { data: '2', operator: '=' } },
      ]);
    });

    it('updates url params after on-filter event', () => {
      findFilteredSearch().vm.$emit('on-filter', [
        { type: 'custom-field[1]', value: { data: '2', operator: '=' } },
      ]);

      expect(updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url: 'http://test.host/?custom-field[1]=2',
      });

      expect(wrapper.emitted('set-filters')).toHaveLength(1);
    });
  });

  describe('custom fields disabled', () => {
    beforeEach(() => {
      createComponent({
        initialFilterParams: {
          'custom-field[1]': '2',
        },
        provide: {
          hasCustomFieldsFeature: false,
        },
      });
    });

    it('does not pass customfield params to FilterSearchBar', () => {
      expect(findFilteredSearch().props('initialFilterValue')).toEqual([]);
    });

    it('does not update url params after on-filter event', () => {
      findFilteredSearch().vm.$emit('on-filter', [
        { type: 'custom-field[1]', value: { data: '2', operator: '=' } },
      ]);

      expect(updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url: 'http://test.host/',
      });

      expect(wrapper.emitted('set-filters')).toHaveLength(1);
    });
  });
});
