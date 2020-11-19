import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon, GlTabs, GlTab } from '@gitlab/ui';

import { mockProjectPath, mockDefaultBranch, mockCiConfigPath, mockCiYml } from './mock_data';
import TextEditor from '~/pipeline_editor/components/text_editor.vue';
import EditorLite from '~/vue_shared/components/editor_lite.vue';
import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';
import PipelineEditorApp from '~/pipeline_editor/pipeline_editor_app.vue';

describe('~/pipeline_editor/pipeline_editor_app.vue', () => {
  let wrapper;

  const createComponent = (
    { props = {}, data = {}, loading = false } = {},
    mountFn = shallowMount,
  ) => {
    wrapper = mountFn(PipelineEditorApp, {
      propsData: {
        projectPath: mockProjectPath,
        defaultBranch: mockDefaultBranch,
        ciConfigPath: mockCiConfigPath,
        ...props,
      },
      data() {
        return data;
      },
      stubs: {
        GlTabs,
        TextEditor,
      },
      mocks: {
        $apollo: {
          queries: {
            content: {
              loading,
            },
          },
        },
      },
    });
  };

  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findAlert = () => wrapper.find(GlAlert);
  const findTabAt = i => wrapper.findAll(GlTab).at(i);
  const findEditorLite = () => wrapper.find(EditorLite);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays content', () => {
    createComponent({ data: { content: mockCiYml } });

    expect(findLoadingIcon().exists()).toBe(false);
    expect(findEditorLite().props('value')).toBe(mockCiYml);
  });

  it('displays a loading icon if the query is loading', () => {
    createComponent({ loading: true });

    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('tabs', () => {
    it('displays tabs and their content', () => {
      createComponent({ data: { content: mockCiYml } });

      expect(
        findTabAt(0)
          .find(EditorLite)
          .exists(),
      ).toBe(true);
      expect(
        findTabAt(1)
          .find(PipelineGraph)
          .exists(),
      ).toBe(true);
    });

    it('displays editor tab lazily, until editor is ready', async () => {
      createComponent({ data: { content: mockCiYml } });

      expect(findTabAt(0).attributes('lazy')).toBe('true');

      findEditorLite().vm.$emit('editor-ready');
      await nextTick();

      expect(findTabAt(0).attributes('lazy')).toBe(undefined);
    });
  });

  describe('when in error state', () => {
    class MockError extends Error {
      constructor(message, data) {
        super(message);
        if (data) {
          this.networkError = {
            response: { data },
          };
        }
      }
    }

    it('shows a generic error', () => {
      const error = new MockError('An error message');
      createComponent({ data: { error } });

      expect(findAlert().text()).toBe('CI file could not be loaded: An error message');
    });

    it('shows a ref missing error state', () => {
      const error = new MockError('Ref missing!', {
        error: 'ref is missing, ref is empty',
      });
      createComponent({ data: { error } });

      expect(findAlert().text()).toMatch(
        'CI file could not be loaded: ref is missing, ref is empty',
      );
    });

    it('shows a file missing error state', async () => {
      const error = new MockError('File missing!', {
        message: 'file not found',
      });

      await wrapper.setData({ error });

      expect(findAlert().text()).toMatch('CI file could not be loaded: file not found');
    });
  });
});
