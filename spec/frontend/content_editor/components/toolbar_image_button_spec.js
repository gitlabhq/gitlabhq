import { GlButton, GlFormInputGroup } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ToolbarImageButton from '~/content_editor/components/toolbar_image_button.vue';
import Attachment from '~/content_editor/extensions/attachment';
import Image from '~/content_editor/extensions/image';
import { createTestEditor, mockChainedCommands } from '../test_utils';

describe('content_editor/components/toolbar_image_button', () => {
  let wrapper;
  let editor;

  const buildWrapper = () => {
    wrapper = mountExtended(ToolbarImageButton, {
      provide: {
        tiptapEditor: editor,
      },
    });
  };

  const findImageURLInput = () =>
    wrapper.findComponent(GlFormInputGroup).find('input[type="text"]');
  const findApplyImageButton = () => wrapper.findComponent(GlButton);

  const selectFile = async (file) => {
    const input = wrapper.find({ ref: 'fileSelector' });

    // override the property definition because `input.files` isn't directly modifyable
    Object.defineProperty(input.element, 'files', { value: [file], writable: true });
    await input.trigger('change');
  };

  beforeEach(() => {
    editor = createTestEditor({
      extensions: [
        Image,
        Attachment.configure({
          renderMarkdown: jest.fn(),
          uploadsPath: '/uploads/',
        }),
      ],
    });

    buildWrapper();
  });

  afterEach(() => {
    editor.destroy();
    wrapper.destroy();
  });

  it('sets the image to the value in the URL input when "Insert" button is clicked', async () => {
    const commands = mockChainedCommands(editor, ['focus', 'setImage', 'run']);

    await findImageURLInput().setValue('https://example.com/img.jpg');
    await findApplyImageButton().trigger('click');

    expect(commands.focus).toHaveBeenCalled();
    expect(commands.setImage).toHaveBeenCalledWith({
      alt: 'img',
      src: 'https://example.com/img.jpg',
      canonicalSrc: 'https://example.com/img.jpg',
    });
    expect(commands.run).toHaveBeenCalled();

    expect(wrapper.emitted().execute[0]).toEqual([{ contentType: 'image', value: 'url' }]);
  });

  it('uploads the selected image when file input changes', async () => {
    const commands = mockChainedCommands(editor, ['focus', 'uploadAttachment', 'run']);
    const file = new File(['foo'], 'foo.png', { type: 'image/png' });

    await selectFile(file);

    expect(commands.focus).toHaveBeenCalled();
    expect(commands.uploadAttachment).toHaveBeenCalledWith({ file });
    expect(commands.run).toHaveBeenCalled();

    expect(wrapper.emitted().execute[0]).toEqual([{ contentType: 'image', value: 'upload' }]);
  });
});
