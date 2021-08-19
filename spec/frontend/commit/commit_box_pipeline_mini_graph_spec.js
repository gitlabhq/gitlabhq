import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CommitBoxPipelineMiniGraph from '~/projects/commit_box/info/components/commit_box_pipeline_mini_graph.vue';
import { mockStages } from './mock_data';

describe('Commit box pipeline mini graph', () => {
  let wrapper;

  const findMiniGraph = () => wrapper.findByTestId('commit-box-mini-graph');
  const findUpstream = () => wrapper.findByTestId('commit-box-mini-graph-upstream');
  const findDownstream = () => wrapper.findByTestId('commit-box-mini-graph-downstream');

  const createComponent = () => {
    wrapper = extendedWrapper(
      shallowMount(CommitBoxPipelineMiniGraph, {
        propsData: {
          stages: mockStages,
        },
        mocks: {
          $apollo: {
            queries: {
              pipeline: {
                loading: false,
              },
            },
          },
        },
      }),
    );
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('linked pipelines', () => {
    it('should display the mini pipeine graph', () => {
      expect(findMiniGraph().exists()).toBe(true);
    });

    it('should not display linked pipelines', () => {
      expect(findUpstream().exists()).toBe(false);
      expect(findDownstream().exists()).toBe(false);
    });
  });
});
