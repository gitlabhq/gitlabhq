import { shallowMount } from '@vue/test-utils';
import { GlDrawer } from '@gitlab/ui';
import PipelineEditorDrawer from '~/ci/pipeline_editor/components/drawer/pipeline_editor_drawer.vue';
import { EDITOR_APP_DRAWER_NONE } from '~/ci/pipeline_editor/constants';

describe('Pipeline editor drawer', () => {
  let wrapper;

  const findDrawer = () => wrapper.findComponent(GlDrawer);

  const createComponent = () => {
    wrapper = shallowMount(PipelineEditorDrawer);
  };

  it('emits close event when closing the drawer', () => {
    createComponent();

    expect(wrapper.emitted('switch-drawer')).toBeUndefined();

    findDrawer().vm.$emit('close');

    expect(wrapper.emitted('switch-drawer')).toEqual([[EDITOR_APP_DRAWER_NONE]]);
  });
});
