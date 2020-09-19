import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { GlFilteredSearch } from '@gitlab/ui';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import PipelinesFilteredSearch from '~/pipelines/components/pipelines_list/pipelines_filtered_search.vue';
import { users, mockSearch, branches, tags } from '../mock_data';

describe('Pipelines filtered search', () => {
  let wrapper;
  let mock;

  const findFilteredSearch = () => wrapper.find(GlFilteredSearch);
  const getSearchToken = type =>
    findFilteredSearch()
      .props('availableTokens')
      .find(token => token.type === type);
  const findBranchToken = () => getSearchToken('ref');
  const findTagToken = () => getSearchToken('tag');
  const findUserToken = () => getSearchToken('username');
  const findStatusToken = () => getSearchToken('status');

  const createComponent = (params = {}) => {
    wrapper = mount(PipelinesFilteredSearch, {
      propsData: {
        projectId: '21',
        params,
      },
      attachToDocument: true,
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
    wrapper.destroy();
    wrapper = null;
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
      operators: [expect.objectContaining({ value: '=' })],
    });

    expect(findBranchToken()).toMatchObject({
      type: 'ref',
      icon: 'branch',
      title: 'Branch name',
      unique: true,
      projectId: '21',
      operators: [expect.objectContaining({ value: '=' })],
    });

    expect(findStatusToken()).toMatchObject({
      type: 'status',
      icon: 'status',
      title: 'Status',
      unique: true,
      operators: [expect.objectContaining({ value: '=' })],
    });

    expect(findTagToken()).toMatchObject({
      type: 'tag',
      icon: 'tag',
      title: 'Tag name',
      unique: true,
      operators: [expect.objectContaining({ value: '=' })],
    });
  });

  it('emits filterPipelines on submit with correct filter', () => {
    findFilteredSearch().vm.$emit('submit', mockSearch);

    expect(wrapper.emitted('filterPipelines')).toBeTruthy();
    expect(wrapper.emitted('filterPipelines')[0]).toEqual([mockSearch]);
  });

  it('disables tag name token when branch name token is active', () => {
    findFilteredSearch().vm.$emit('input', [
      { type: 'ref', value: { data: 'branch-1', operator: '=' } },
      { type: 'filtered-search-term', value: { data: '' } },
    ]);

    return wrapper.vm.$nextTick().then(() => {
      expect(findBranchToken().disabled).toBe(false);
      expect(findTagToken().disabled).toBe(true);
    });
  });

  it('disables branch name token when tag name token is active', () => {
    findFilteredSearch().vm.$emit('input', [
      { type: 'tag', value: { data: 'tag-1', operator: '=' } },
      { type: 'filtered-search-term', value: { data: '' } },
    ]);

    return wrapper.vm.$nextTick().then(() => {
      expect(findBranchToken().disabled).toBe(true);
      expect(findTagToken().disabled).toBe(false);
    });
  });

  it('resets tokens disabled state on clear', () => {
    findFilteredSearch().vm.$emit('clearInput');

    return wrapper.vm.$nextTick().then(() => {
      expect(findBranchToken().disabled).toBe(false);
      expect(findTagToken().disabled).toBe(false);
    });
  });

  it('resets tokens disabled state when clearing tokens by backspace', () => {
    findFilteredSearch().vm.$emit('input', [{ type: 'filtered-search-term', value: { data: '' } }]);

    return wrapper.vm.$nextTick().then(() => {
      expect(findBranchToken().disabled).toBe(false);
      expect(findTagToken().disabled).toBe(false);
    });
  });

  describe('Url query params', () => {
    const params = {
      username: 'deja.green',
      ref: 'master',
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
        { type: 'filtered-search-term', value: { data: '' } },
      ];

      expect(findFilteredSearch().props('value')).toEqual(expectedValueProp);
      expect(findFilteredSearch().props('value')).toHaveLength(expectedValueProp.length);
    });
  });
});
