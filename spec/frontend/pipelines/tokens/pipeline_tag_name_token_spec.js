import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Api from '~/api';
import PipelineTagNameToken from '~/pipelines/components/pipelines_list/tokens/pipeline_tag_name_token.vue';
import { tags, mockTagsAfterMap } from '../mock_data';

describe('Pipeline Branch Name Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.find(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () => wrapper.findAll(GlFilteredSearchSuggestion);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const stubs = {
    GlFilteredSearchToken: {
      template: `<div><slot name="suggestions"></slot></div>`,
    },
  };

  const defaultProps = {
    config: {
      type: 'tag',
      icon: 'tag',
      title: 'Tag name',
      unique: true,
      projectId: '21',
      disabled: false,
    },
    value: {
      data: '',
    },
  };

  const createComponent = (options, data) => {
    wrapper = shallowMount(PipelineTagNameToken, {
      propsData: {
        ...defaultProps,
      },
      data() {
        return {
          ...data,
        };
      },
      ...options,
    });
  };

  beforeEach(() => {
    jest.spyOn(Api, 'tags').mockResolvedValue({ data: tags });

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('passes config correctly', () => {
    expect(findFilteredSearchToken().props('config')).toEqual(defaultProps.config);
  });

  it('fetches and sets project tags', () => {
    expect(Api.tags).toHaveBeenCalled();

    expect(wrapper.vm.tags).toEqual(mockTagsAfterMap);
    expect(findLoadingIcon().exists()).toBe(false);
  });

  describe('displays loading icon correctly', () => {
    it('shows loading icon', () => {
      createComponent({ stubs }, { loading: true });

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not show loading icon', () => {
      createComponent({ stubs }, { loading: false });

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('shows tags correctly', () => {
    it('renders all tags', () => {
      createComponent({ stubs }, { tags, loading: false });

      expect(findAllFilteredSearchSuggestions()).toHaveLength(tags.length);
    });

    it('renders only the tag searched for', () => {
      const mockTags = ['main-tag'];
      createComponent({ stubs }, { tags: mockTags, loading: false });

      expect(findAllFilteredSearchSuggestions()).toHaveLength(mockTags.length);
    });
  });
});
