import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import PipelineStatusToken from '~/pipelines/components/pipelines_list/tokens/pipeline_status_token.vue';

describe('Pipeline Status Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.find(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () => wrapper.findAll(GlFilteredSearchSuggestion);
  const findAllGlIcons = () => wrapper.findAll(GlIcon);

  const defaultProps = {
    config: {
      type: 'status',
      icon: 'status',
      title: 'Status',
      unique: true,
    },
    value: {
      data: '',
    },
  };

  const createComponent = () => {
    wrapper = shallowMount(PipelineStatusToken, {
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('passes config correctly', () => {
    expect(findFilteredSearchToken().props('config')).toEqual(defaultProps.config);
  });

  describe('shows statuses correctly', () => {
    it('renders all pipeline statuses available', () => {
      expect(findAllFilteredSearchSuggestions()).toHaveLength(wrapper.vm.statuses.length);
      expect(findAllGlIcons()).toHaveLength(wrapper.vm.statuses.length);
    });
  });
});
