import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CiConfigMergedPreview from '~/pipeline_editor/components/editor/ci_config_merged_preview.vue';
import CiLint from '~/pipeline_editor/components/lint/ci_lint.vue';
import PipelineEditorTabs from '~/pipeline_editor/components/pipeline_editor_tabs.vue';
import EditorTab from '~/pipeline_editor/components/ui/editor_tab.vue';
import {
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_STATUS_ERROR,
  EDITOR_APP_STATUS_LOADING,
  EDITOR_APP_STATUS_INVALID,
  EDITOR_APP_STATUS_VALID,
} from '~/pipeline_editor/constants';
import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';
import { mockLintResponse, mockCiYml } from '../mock_data';

describe('Pipeline editor tabs component', () => {
  let wrapper;
  const MockTextEditor = {
    template: '<div />',
  };

  const createComponent = ({
    props = {},
    provide = {},
    appStatus = EDITOR_APP_STATUS_VALID,
    mountFn = shallowMount,
  } = {}) => {
    wrapper = mountFn(PipelineEditorTabs, {
      propsData: {
        ciConfigData: mockLintResponse,
        ciFileContent: mockCiYml,
        ...props,
      },
      data() {
        return {
          appStatus,
        };
      },
      provide: { ...provide },
      stubs: {
        TextEditor: MockTextEditor,
        EditorTab,
      },
    });
  };

  const findEditorTab = () => wrapper.find('[data-testid="editor-tab"]');
  const findLintTab = () => wrapper.find('[data-testid="lint-tab"]');
  const findMergedTab = () => wrapper.find('[data-testid="merged-tab"]');
  const findVisualizationTab = () => wrapper.find('[data-testid="visualization-tab"]');

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCiLint = () => wrapper.findComponent(CiLint);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPipelineGraph = () => wrapper.findComponent(PipelineGraph);
  const findTextEditor = () => wrapper.findComponent(MockTextEditor);
  const findMergedPreview = () => wrapper.findComponent(CiConfigMergedPreview);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('editor tab', () => {
    it('displays editor only after the tab is mounted', async () => {
      createComponent({ mountFn: mount });

      expect(findTextEditor().exists()).toBe(false);

      await nextTick();

      expect(findTextEditor().exists()).toBe(true);
      expect(findEditorTab().exists()).toBe(true);
    });
  });

  describe('visualization tab', () => {
    describe('while loading', () => {
      beforeEach(() => {
        createComponent({ appStatus: EDITOR_APP_STATUS_LOADING });
      });

      it('displays a loading icon if the lint query is loading', () => {
        expect(findLoadingIcon().exists()).toBe(true);
        expect(findPipelineGraph().exists()).toBe(false);
      });
    });
    describe('after loading', () => {
      beforeEach(() => {
        createComponent();
      });

      it('display the tab and visualization', () => {
        expect(findVisualizationTab().exists()).toBe(true);
        expect(findPipelineGraph().exists()).toBe(true);
      });
    });
  });

  describe('lint tab', () => {
    describe('while loading', () => {
      beforeEach(() => {
        createComponent({ appStatus: EDITOR_APP_STATUS_LOADING });
      });

      it('displays a loading icon if the lint query is loading', () => {
        expect(findLoadingIcon().exists()).toBe(true);
      });

      it('does not display the lint component', () => {
        expect(findCiLint().exists()).toBe(false);
      });
    });
    describe('after loading', () => {
      beforeEach(() => {
        createComponent();
      });

      it('display the tab and the lint component', () => {
        expect(findLintTab().exists()).toBe(true);
        expect(findCiLint().exists()).toBe(true);
      });
    });
  });

  describe('merged tab', () => {
    describe('while loading', () => {
      beforeEach(() => {
        createComponent({ appStatus: EDITOR_APP_STATUS_LOADING });
      });

      it('displays a loading icon if the lint query is loading', () => {
        expect(findLoadingIcon().exists()).toBe(true);
      });
    });

    describe('when there is a fetch error', () => {
      beforeEach(() => {
        createComponent({ appStatus: EDITOR_APP_STATUS_ERROR });
      });

      it('show an error message', () => {
        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(wrapper.vm.$options.errorTexts.loadMergedYaml);
      });

      it('does not render the `merged_preview` component', () => {
        expect(findMergedPreview().exists()).toBe(false);
      });
    });

    describe('after loading', () => {
      beforeEach(() => {
        createComponent();
      });

      it('display the tab and the merged preview component', () => {
        expect(findMergedTab().exists()).toBe(true);
        expect(findMergedPreview().exists()).toBe(true);
      });
    });
  });

  describe('show tab content based on status', () => {
    it.each`
      appStatus                    | editor  | viz      | lint     | merged
      ${undefined}                 | ${true} | ${true}  | ${true}  | ${true}
      ${EDITOR_APP_STATUS_EMPTY}   | ${true} | ${false} | ${false} | ${false}
      ${EDITOR_APP_STATUS_INVALID} | ${true} | ${false} | ${true}  | ${false}
      ${EDITOR_APP_STATUS_VALID}   | ${true} | ${true}  | ${true}  | ${true}
    `(
      'when status is $appStatus, we show - editor:$editor | viz:$viz | lint:$lint | merged:$merged ',
      ({ appStatus, editor, viz, lint, merged }) => {
        createComponent({ appStatus });

        expect(findTextEditor().exists()).toBe(editor);
        expect(findPipelineGraph().exists()).toBe(viz);
        expect(findCiLint().exists()).toBe(lint);
        expect(findMergedPreview().exists()).toBe(merged);
      },
    );
  });
});
