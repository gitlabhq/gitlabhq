import { nextTick } from 'vue';
import { mount, shallowMount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';

import { mockProjectPath, mockDefaultBranch, mockCiConfigPath, mockCiYml } from './mock_data';
import TextEditor from '~/pipeline_editor/components/text_editor.vue';
import EditorLite from '~/vue_shared/components/editor_lite.vue';
import PipelineEditorApp from '~/pipeline_editor/pipeline_editor_app.vue';

describe('~/pipeline_editor/pipeline_editor_app.vue', () => {
  let wrapper;

  const createComponent = ({ props = {}, loading = false } = {}, mountFn = shallowMount) => {
    wrapper = mountFn(PipelineEditorApp, {
      propsData: {
        projectPath: mockProjectPath,
        defaultBranch: mockDefaultBranch,
        ciConfigPath: mockCiConfigPath,
        ...props,
      },
      stubs: {
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
  const findEditor = () => wrapper.find(EditorLite);

  it('displays content', async () => {
    createComponent();
    wrapper.setData({ content: mockCiYml });
    await nextTick();

    expect(findLoadingIcon().exists()).toBe(false);
    expect(findEditor().props('value')).toBe(mockCiYml);
  });

  it('displays a loading icon if the query is loading', async () => {
    createComponent({ loading: true });

    expect(findLoadingIcon().exists()).toBe(true);
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

    beforeEach(() => {
      createComponent(mount);
    });

    it('shows a generic error', async () => {
      wrapper.setData({ error: new MockError('An error message') });
      await nextTick();

      expect(findAlert().text()).toBe('CI file could not be loaded: An error message');
    });

    it('shows a ref missing error state', async () => {
      const error = new MockError('Ref missing!', {
        error: 'ref is missing, ref is empty',
      });

      wrapper.setData({ error });
      await nextTick();

      expect(findAlert().text()).toMatch(
        'CI file could not be loaded: ref is missing, ref is empty',
      );
    });

    it('shows a file missing error state', async () => {
      const error = new MockError('File missing!', {
        message: 'file not found',
      });

      wrapper.setData({ error });
      await nextTick();

      expect(findAlert().text()).toMatch('CI file could not be loaded: file not found');
    });
  });
});
