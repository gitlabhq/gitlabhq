import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineTriggerAuthorToken from '~/pipelines/components/tokens/pipeline_trigger_author_token.vue';
import { users } from '../mock_data';

describe('Pipeline Trigger Author Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.find(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () => wrapper.findAll(GlFilteredSearchSuggestion);

  const stubs = {
    GlFilteredSearchToken: {
      template: `<div><slot name="suggestions"></slot></div>`,
    },
  };

  const defaultProps = {
    config: {
      type: 'username',
      icon: 'user',
      title: 'Trigger author',
      dataType: 'username',
      unique: true,
      triggerAuthors: users,
    },
  };

  const createComponent = (props = {}, options) => {
    wrapper = shallowMount(PipelineTriggerAuthorToken, {
      propsData: {
        ...props,
        ...defaultProps,
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent({ value: { data: '' } });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('passes config correctly', () => {
    expect(findFilteredSearchToken().props('config')).toEqual(defaultProps.config);
  });

  describe('shows trigger authors correctly', () => {
    it('renders all trigger authors', () => {
      createComponent({ value: { data: '' } }, { stubs });
      expect(findAllFilteredSearchSuggestions()).toHaveLength(7);
    });

    it('renders only the trigger author searched for', () => {
      createComponent({ value: { data: 'root' } }, { stubs });
      expect(findAllFilteredSearchSuggestions()).toHaveLength(2);
    });
  });
});
