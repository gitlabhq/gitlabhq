import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import TextViewer from '~/repository/components/blob_viewers/text_viewer.vue';
import SourceEditor from '~/vue_shared/components/source_editor.vue';

describe('Text Viewer', () => {
  let wrapper;
  const propsData = {
    content: 'Some content',
    fileName: 'file_name.js',
    readOnly: true,
  };

  const createComponent = () => {
    wrapper = shallowMount(TextViewer, { propsData });
  };

  const findEditor = () => wrapper.findComponent(SourceEditor);

  it('renders a Source Editor component', async () => {
    createComponent();

    await waitForPromises();

    expect(findEditor().exists()).toBe(true);
    expect(findEditor().props('value')).toBe(propsData.content);
    expect(findEditor().props('fileName')).toBe(propsData.fileName);
    expect(findEditor().props('editorOptions')).toEqual({ readOnly: propsData.readOnly });
  });
});
