import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { PIPELINE_SOURCES } from 'ee_else_ce/ci/pipelines_page/tokens/constants';
import { stubComponent } from 'helpers/stub_component';
import PipelineSourceToken from '~/ci/pipelines_page/tokens/pipeline_source_token.vue';

describe('Pipeline Source Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () =>
    wrapper.findAllComponents(GlFilteredSearchSuggestion);

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
    cursorPosition: 'start',
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
      expect(findAllFilteredSearchSuggestions()).toHaveLength(PIPELINE_SOURCES.length);
    });
  });
});
