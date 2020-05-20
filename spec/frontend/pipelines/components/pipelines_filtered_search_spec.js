import Api from '~/api';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import PipelinesFilteredSearch from '~/pipelines/components/pipelines_filtered_search.vue';
import { users, mockSearch, pipelineWithStages, branches } from '../mock_data';
import { GlFilteredSearch } from '@gitlab/ui';

describe('Pipelines filtered search', () => {
  let wrapper;
  let mock;

  const findFilteredSearch = () => wrapper.find(GlFilteredSearch);
  const getSearchToken = type =>
    findFilteredSearch()
      .props('availableTokens')
      .find(token => token.type === type);

  const createComponent = (params = {}) => {
    wrapper = mount(PipelinesFilteredSearch, {
      propsData: {
        pipelines: [pipelineWithStages],
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

    createComponent();
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
    wrapper = null;
  });

  it('displays UI elements', () => {
    expect(wrapper.isVueInstance()).toBe(true);
    expect(wrapper.isEmpty()).toBe(false);

    expect(findFilteredSearch().exists()).toBe(true);
  });

  it('displays search tokens', () => {
    expect(getSearchToken('username')).toMatchObject({
      type: 'username',
      icon: 'user',
      title: 'Trigger author',
      unique: true,
      projectId: '21',
      operators: [expect.objectContaining({ value: '=' })],
    });

    expect(getSearchToken('ref')).toMatchObject({
      type: 'ref',
      icon: 'branch',
      title: 'Branch name',
      unique: true,
      projectId: '21',
      operators: [expect.objectContaining({ value: '=' })],
    });
  });

  it('emits filterPipelines on submit with correct filter', () => {
    findFilteredSearch().vm.$emit('submit', mockSearch);

    expect(wrapper.emitted('filterPipelines')).toBeTruthy();
    expect(wrapper.emitted('filterPipelines')[0]).toEqual([mockSearch]);
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
