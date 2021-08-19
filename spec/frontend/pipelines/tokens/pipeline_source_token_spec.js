import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import PipelineSourceToken from '~/pipelines/components/pipelines_list/tokens/pipeline_source_token.vue';

describe('Pipeline Source Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.find(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () => wrapper.findAll(GlFilteredSearchSuggestion);

  const defaultProps = {
    config: {
      type: 'source',
      icon: 'trigger-source',
      title: 'Source',
      unique: true,
    },
    value: {
      data: '',
    },
  };

  const createComponent = () => {
    wrapper = shallowMount(PipelineSourceToken, {
      propsData: {
        ...defaultProps,
      },
      stubs: {
        GlFilteredSearchToken: stubComponent(GlFilteredSearchToken, {
          template: `<div><slot name="suggestions"></slot></div>`,
        }),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('passes config correctly', () => {
    expect(findFilteredSearchToken().props('config')).toEqual(defaultProps.config);
  });

  describe('shows sources correctly', () => {
    it('renders all pipeline sources available', () => {
      expect(findAllFilteredSearchSuggestions()).toHaveLength(wrapper.vm.sources.length);
    });
  });
});
