import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

import CommitSection from '~/pipeline_editor/components/commit/commit_section.vue';
import PipelineEditorDrawer from '~/pipeline_editor/components/drawer/pipeline_editor_drawer.vue';
import PipelineEditorFileNav from '~/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';
import PipelineEditorHeader from '~/pipeline_editor/components/header/pipeline_editor_header.vue';
import PipelineEditorTabs from '~/pipeline_editor/components/pipeline_editor_tabs.vue';
import { MERGED_TAB, VISUALIZE_TAB, CREATE_TAB, LINT_TAB } from '~/pipeline_editor/constants';
import PipelineEditorHome from '~/pipeline_editor/pipeline_editor_home.vue';

import { mockLintResponse, mockCiYml } from './mock_data';

describe('Pipeline editor home wrapper', () => {
  let wrapper;

  const createComponent = ({ props = {}, glFeatures = {} } = {}) => {
    wrapper = shallowMount(PipelineEditorHome, {
      propsData: {
        ciConfigData: mockLintResponse,
        ciFileContent: mockCiYml,
        isCiConfigDataLoading: false,
        isNewCiConfigFile: false,
        ...props,
      },
      provide: {
        glFeatures: {
          ...glFeatures,
        },
      },
    });
  };

  const findCommitSection = () => wrapper.findComponent(CommitSection);
  const findFileNav = () => wrapper.findComponent(PipelineEditorFileNav);
  const findPipelineEditorDrawer = () => wrapper.findComponent(PipelineEditorDrawer);
  const findPipelineEditorHeader = () => wrapper.findComponent(PipelineEditorHeader);
  const findPipelineEditorTabs = () => wrapper.findComponent(PipelineEditorTabs);

  afterEach(() => {
    wrapper.destroy();
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

    it('show the pipeline drawer', () => {
      expect(findPipelineEditorDrawer().exists()).toBe(true);
    });
  });

  describe('commit form toggle', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      tab              | shouldShow
      ${MERGED_TAB}    | ${false}
      ${VISUALIZE_TAB} | ${false}
      ${LINT_TAB}      | ${false}
      ${CREATE_TAB}    | ${true}
    `(
      'when the active tab is $tab the commit form is shown: $shouldShow',
      async ({ tab, shouldShow }) => {
        expect(findCommitSection().exists()).toBe(true);

        findPipelineEditorTabs().vm.$emit('set-current-tab', tab);

        await nextTick();

        expect(findCommitSection().exists()).toBe(shouldShow);
      },
    );

    it('shows the commit form again when coming back to the create tab', async () => {
      expect(findCommitSection().exists()).toBe(true);

      findPipelineEditorTabs().vm.$emit('set-current-tab', MERGED_TAB);
      await nextTick();
      expect(findCommitSection().exists()).toBe(false);

      findPipelineEditorTabs().vm.$emit('set-current-tab', CREATE_TAB);
      await nextTick();
      expect(findCommitSection().exists()).toBe(true);
    });
  });
});
