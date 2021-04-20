import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

import CommitSection from '~/pipeline_editor/components/commit/commit_section.vue';
import PipelineEditorFileNav from '~/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';
import PipelineEditorHeader from '~/pipeline_editor/components/header/pipeline_editor_header.vue';
import PipelineEditorTabs from '~/pipeline_editor/components/pipeline_editor_tabs.vue';
import { MERGED_TAB, VISUALIZE_TAB } from '~/pipeline_editor/constants';
import PipelineEditorHome from '~/pipeline_editor/pipeline_editor_home.vue';

import { mockLintResponse, mockCiYml } from './mock_data';

describe('Pipeline editor home wrapper', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(PipelineEditorHome, {
      propsData: {
        ciConfigData: mockLintResponse,
        ciFileContent: mockCiYml,
        isCiConfigDataLoading: false,
        isNewCiConfigFile: false,
        ...props,
      },
    });
  };

  const findPipelineEditorHeader = () => wrapper.findComponent(PipelineEditorHeader);
  const findPipelineEditorTabs = () => wrapper.findComponent(PipelineEditorTabs);
  const findCommitSection = () => wrapper.findComponent(CommitSection);
  const findFileNav = () => wrapper.findComponent(PipelineEditorFileNav);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('renders', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the file nav', () => {
      expect(findFileNav().exists()).toBe(true);
    });

    it('shows the pipeline editor header', () => {
      expect(findPipelineEditorHeader().exists()).toBe(true);
    });

    it('shows the pipeline editor tabs', () => {
      expect(findPipelineEditorTabs().exists()).toBe(true);
    });

    it('shows the commit section by default', () => {
      expect(findCommitSection().exists()).toBe(true);
    });
  });

  describe('commit form toggle', () => {
    beforeEach(() => {
      createComponent();
    });

    it('hides the commit form when in the merged tab', async () => {
      expect(findCommitSection().exists()).toBe(true);

      findPipelineEditorTabs().vm.$emit('set-current-tab', MERGED_TAB);
      await nextTick();
      expect(findCommitSection().exists()).toBe(false);
    });

    it('shows the form again when leaving the merged tab', async () => {
      expect(findCommitSection().exists()).toBe(true);

      findPipelineEditorTabs().vm.$emit('set-current-tab', MERGED_TAB);
      await nextTick();
      expect(findCommitSection().exists()).toBe(false);

      findPipelineEditorTabs().vm.$emit('set-current-tab', VISUALIZE_TAB);
      await nextTick();
      expect(findCommitSection().exists()).toBe(true);
    });
  });
});
