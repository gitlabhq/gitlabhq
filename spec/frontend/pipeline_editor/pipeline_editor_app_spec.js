import { mount, shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';

import PipelineEditorApp from '~/pipeline_editor/pipeline_editor_app.vue';

describe('~/pipeline_editor/pipeline_editor_app.vue', () => {
  let wrapper;

  const createComponent = (mountFn = shallowMount) => {
    wrapper = mountFn(PipelineEditorApp);
  };

  const findEmptyState = () => wrapper.find(GlEmptyState);

  it('contains an empty state', () => {
    createComponent();

    expect(findEmptyState().exists()).toBe(true);
  });

  it('contains a text description', () => {
    createComponent(mount);

    expect(findEmptyState().text()).toMatchInterpolatedText(
      'Pipeline Editor We are beginning our work around building the foundation for our dedicated pipeline editor. Learn more',
    );
  });
});
