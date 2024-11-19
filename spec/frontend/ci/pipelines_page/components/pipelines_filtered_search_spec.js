import { GlFilteredSearch } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import PipelinesFilteredSearch from '~/ci/pipelines_page/components/pipelines_filtered_search.vue';
import {
  FILTERED_SEARCH_TERM,
  OPERATORS_IS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { TRACKING_CATEGORIES } from '~/ci/constants';
import { branches, mockSearch, tags, users } from 'jest/ci/pipeline_details/mock_data';

describe('Pipelines filtered search', () => {
  let wrapper;
  let mock;

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const getSearchToken = (type) =>
    findFilteredSearch()
      .props('availableTokens')
      .find((token) => token.type === type);
  const findBranchToken = () => getSearchToken('ref');
  const findTagToken = () => getSearchToken('tag');
  const findUserToken = () => getSearchToken('username');
  const findStatusToken = () => getSearchToken('status');
  const findSourceToken = () => getSearchToken('source');

  const createComponent = (params = {}) => {
    wrapper = mount(PipelinesFilteredSearch, {
      propsData: {
        params,
      },
      provide: {
        defaultBranchName: 'main',
        projectId: '21',
      },
      attachTo: document.body,
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    jest.spyOn(Api, 'projectUsers').mockResolvedValue(users);
    jest.spyOn(Api, 'branches').mockResolvedValue({ data: branches });
    jest.spyOn(Api, 'tags').mockResolvedValue({ data: tags });

    createComponent();
  });

  afterEach(() => {
    mock.restore();
  });

  it('displays UI elements', () => {
    expect(findFilteredSearch().exists()).toBe(true);
  });

  it('displays search tokens', () => {
    expect(findUserToken()).toMatchObject({
      type: 'username',
      icon: 'user',
      title: 'Trigger author',
      unique: true,
      projectId: '21',
      operators: OPERATORS_IS,
    });

    expect(findBranchToken()).toMatchObject({
      type: 'ref',
      icon: 'branch',
      title: 'Branch name',
      unique: true,
      projectId: '21',
      defaultBranchName: 'main',
      operators: OPERATORS_IS,
    });

    expect(findSourceToken()).toMatchObject({
      type: 'source',
      icon: 'trigger-source',
      title: 'Source',
      unique: true,
      operators: OPERATORS_IS,
    });

    expect(findStatusToken()).toMatchObject({
      type: 'status',
      icon: 'status',
      title: 'Status',
      unique: true,
      operators: OPERATORS_IS,
    });

    expect(findTagToken()).toMatchObject({
      type: 'tag',
      icon: 'tag',
      title: 'Tag name',
      unique: true,
      operators: OPERATORS_IS,
    });
  });

  it('emits filterPipelines on submit with correct filter', () => {
    findFilteredSearch().vm.$emit('submit', mockSearch);

    expect(wrapper.emitted('filterPipelines')).toHaveLength(1);
    expect(wrapper.emitted('filterPipelines')[0]).toEqual([mockSearch]);
  });

  it('disables tag name token when branch name token is active', async () => {
    findFilteredSearch().vm.$emit('input', [
      { type: 'ref', value: { data: 'branch-1', operator: '=' } },
      { type: FILTERED_SEARCH_TERM, value: { data: '' } },
    ]);

    await nextTick();
    expect(findBranchToken().disabled).toBe(false);
    expect(findTagToken().disabled).toBe(true);
  });

  it('disables branch name token when tag name token is active', async () => {
    findFilteredSearch().vm.$emit('input', [
      { type: 'tag', value: { data: 'tag-1', operator: '=' } },
      { type: FILTERED_SEARCH_TERM, value: { data: '' } },
    ]);

    await nextTick();
    expect(findBranchToken().disabled).toBe(true);
    expect(findTagToken().disabled).toBe(false);
  });

  it('resets tokens disabled state on clear', async () => {
    findFilteredSearch().vm.$emit('clearInput');

    await nextTick();
    expect(findBranchToken().disabled).toBe(false);
    expect(findTagToken().disabled).toBe(false);
  });

  it('resets tokens disabled state when clearing tokens by backspace', async () => {
    findFilteredSearch().vm.$emit('input', [{ type: FILTERED_SEARCH_TERM, value: { data: '' } }]);

    await nextTick();
    expect(findBranchToken().disabled).toBe(false);
    expect(findTagToken().disabled).toBe(false);
  });

  describe('Url query params', () => {
    const params = {
      username: 'deja.green',
      ref: 'main',
    };

    beforeEach(() => {
      createComponent(params);
    });

    it('sets default value if url query params', () => {
      const expectedValueProp = [
        {
          type: 'username',
          value: {
            data: params.username,
            operator: '=',
          },
        },
        {
          type: 'ref',
          value: {
            data: params.ref,
            operator: '=',
          },
        },
        { type: FILTERED_SEARCH_TERM, value: { data: '' } },
      ];

      expect(findFilteredSearch().props('value')).toMatchObject(expectedValueProp);
      expect(findFilteredSearch().props('value')).toHaveLength(expectedValueProp.length);
    });
  });

  describe('tracking', () => {
    afterEach(() => {
      unmockTracking();
    });

    it('tracks filtered search click', () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      findFilteredSearch().vm.$emit('submit', mockSearch);

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_filtered_search', {
        label: TRACKING_CATEGORIES.search,
      });
    });
  });
});
