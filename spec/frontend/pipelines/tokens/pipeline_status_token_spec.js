import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineStatusToken from '~/pipelines/components/tokens/pipeline_status_token.vue';

describe('Pipeline Status Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.find(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () => wrapper.findAll(GlFilteredSearchSuggestion);
  const findAllGlIcons = () => wrapper.findAll(GlIcon);

  const stubs = {
    GlFilteredSearchToken: {
      template: `<div><slot name="suggestions"></slot></div>`,
    },
  };

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

  const createComponent = options => {
    wrapper = shallowMount(PipelineStatusToken, {
      propsData: {
        ...defaultProps,
      },
      ...options,
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
    beforeEach(() => {
      createComponent({ stubs });
    });

    it('renders all pipeline statuses available', () => {
      expect(findAllFilteredSearchSuggestions()).toHaveLength(wrapper.vm.statuses.length);
      expect(findAllGlIcons()).toHaveLength(wrapper.vm.statuses.length);
    });
  });
});
