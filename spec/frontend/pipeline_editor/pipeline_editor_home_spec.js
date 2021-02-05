import { shallowMount } from '@vue/test-utils';

import PipelineEditorHome from '~/pipeline_editor/pipeline_editor_home.vue';
import PipelineEditorTabs from '~/pipeline_editor/components/pipeline_editor_tabs.vue';
import CommitSection from '~/pipeline_editor/components/commit/commit_section.vue';
import PipelineEditorHeader from '~/pipeline_editor/components/header/pipeline_editor_header.vue';

import { mockLintResponse, mockCiYml } from './mock_data';

describe('Pipeline editor home wrapper', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(PipelineEditorHome, {
      propsData: {
        ciConfigData: mockLintResponse,
        ciFileContent: mockCiYml,
        isCiConfigDataLoading: false,
        ...props,
      },
    });
  };

  const findPipelineEditorHeader = () => wrapper.findComponent(PipelineEditorTabs);
  const findPipelineEditorTabs = () => wrapper.findComponent(CommitSection);
  const findCommitSection = () => wrapper.findComponent(PipelineEditorHeader);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('renders', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the pipeline editor header', () => {
      expect(findPipelineEditorHeader().exists()).toBe(true);
    });

    it('shows the pipeline editor tabs', () => {
      expect(findPipelineEditorTabs().exists()).toBe(true);
    });

    it('shows the commit section', () => {
      expect(findCommitSection().exists()).toBe(true);
    });
  });
});
