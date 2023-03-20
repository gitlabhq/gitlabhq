import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DrawioToolbarButton from '~/vue_shared/components/markdown/drawio_toolbar_button.vue';
import { launchDrawioEditor } from '~/drawio/drawio_editor';
import { create } from '~/drawio/markdown_field_editor_facade';

jest.mock('~/drawio/drawio_editor');
jest.mock('~/drawio/markdown_field_editor_facade');

describe('vue_shared/components/markdown/drawio_toolbar_button', () => {
  let wrapper;
  let textArea;
  const uploadsPath = '/uploads';
  const markdownPreviewPath = '/markdown/preview';

  const buildWrapper = (props = { uploadsPath, markdownPreviewPath }) => {
    wrapper = shallowMount(DrawioToolbarButton, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    textArea = document.createElement('textarea');
    textArea.classList.add('js-gfm-input');

    document.body.appendChild(textArea);
  });

  afterEach(() => {
    textArea.remove();
  });

  describe('default', () => {
    it('renders button that launches draw.io editor', () => {
      buildWrapper();

      expect(wrapper.findComponent(GlButton).props()).toMatchObject({
        icon: 'diagram',
        category: 'tertiary',
      });
    });
  });

  describe('when clicking button', () => {
    it('launches draw.io editor', async () => {
      const editorFacadeStub = {};

      create.mockReturnValueOnce(editorFacadeStub);

      buildWrapper();

      await wrapper.findComponent(GlButton).vm.$emit('click');

      expect(create).toHaveBeenCalledWith({
        markdownPreviewPath,
        textArea,
        uploadsPath,
      });
      expect(launchDrawioEditor).toHaveBeenCalledWith({
        editorFacade: editorFacadeStub,
      });
    });
  });
});
