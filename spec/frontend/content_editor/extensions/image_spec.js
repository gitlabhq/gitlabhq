import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { once } from 'lodash';
import waitForPromises from 'helpers/wait_for_promises';
import * as Image from '~/content_editor/extensions/image';
import httpStatus from '~/lib/utils/http_status';
import { loadMarkdownApiResult } from '../markdown_processing_examples';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/extensions/image', () => {
  let tiptapEditor;
  let eq;
  let doc;
  let p;
  let image;
  let renderMarkdown;
  let mock;
  const uploadsPath = '/uploads/';
  const validFile = new File(['foo'], 'foo.png', { type: 'image/png' });
  const invalidFile = new File(['foo'], 'bar.html', { type: 'text/html' });

  beforeEach(() => {
    renderMarkdown = jest
      .fn()
      .mockResolvedValue(loadMarkdownApiResult('project_wiki_attachment_image').body);

    const { tiptapExtension } = Image.configure({ renderMarkdown, uploadsPath });

    tiptapEditor = createTestEditor({ extensions: [tiptapExtension] });

    ({
      builders: { doc, p, image },
      eq,
    } = createDocBuilder({
      tiptapEditor,
      names: { image: { nodeType: tiptapExtension.name } },
    }));

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.reset();
  });

  it.each`
    file           | valid    | description
    ${validFile}   | ${true}  | ${'handles paste event when mime type is valid'}
    ${invalidFile} | ${false} | ${'does not handle paste event when mime type is invalid'}
  `('$description', ({ file, valid }) => {
    const pasteEvent = Object.assign(new Event('paste'), {
      clipboardData: {
        files: [file],
      },
    });
    let handled;

    tiptapEditor.view.someProp('handlePaste', (eventHandler) => {
      handled = eventHandler(tiptapEditor.view, pasteEvent);
    });

    expect(handled).toBe(valid);
  });

  it.each`
    file           | valid    | description
    ${validFile}   | ${true}  | ${'handles drop event when mime type is valid'}
    ${invalidFile} | ${false} | ${'does not handle drop event when mime type is invalid'}
  `('$description', ({ file, valid }) => {
    const dropEvent = Object.assign(new Event('drop'), {
      dataTransfer: {
        files: [file],
      },
    });
    let handled;

    tiptapEditor.view.someProp('handleDrop', (eventHandler) => {
      handled = eventHandler(tiptapEditor.view, dropEvent);
    });

    expect(handled).toBe(valid);
  });

  it('handles paste event when mime type is correct', () => {
    const pasteEvent = Object.assign(new Event('paste'), {
      clipboardData: {
        files: [new File(['foo'], 'foo.png', { type: 'image/png' })],
      },
    });
    const handled = tiptapEditor.view.someProp('handlePaste', (eventHandler) => {
      return eventHandler(tiptapEditor.view, pasteEvent);
    });

    expect(handled).toBe(true);
  });

  describe('uploadImage command', () => {
    describe('when file has correct mime type', () => {
      let initialDoc;
      const base64EncodedFile = 'data:image/png;base64,Zm9v';

      beforeEach(() => {
        initialDoc = doc(p(''));
        tiptapEditor.commands.setContent(initialDoc.toJSON());
      });

      describe('when uploading image succeeds', () => {
        const successResponse = {
          link: {
            markdown: '[image](/uploads/25265/image.png)',
          },
        };

        beforeEach(() => {
          mock.onPost().reply(httpStatus.OK, successResponse);
        });

        it('inserts an image with src set to the encoded image file and uploading true', (done) => {
          const expectedDoc = doc(p(image({ uploading: true, src: base64EncodedFile })));

          tiptapEditor.on(
            'update',
            once(() => {
              expect(eq(tiptapEditor.state.doc, expectedDoc)).toBe(true);
              done();
            }),
          );

          tiptapEditor.commands.uploadImage({ file: validFile });
        });

        it('updates the inserted image with canonicalSrc when upload is successful', async () => {
          const expectedDoc = doc(
            p(
              image({
                canonicalSrc: 'test-file.png',
                src: base64EncodedFile,
                alt: 'test file',
                uploading: false,
              }),
            ),
          );

          tiptapEditor.commands.uploadImage({ file: validFile });

          await waitForPromises();

          expect(eq(tiptapEditor.state.doc, expectedDoc)).toBe(true);
        });
      });

      describe('when uploading image request fails', () => {
        beforeEach(() => {
          mock.onPost().reply(httpStatus.INTERNAL_SERVER_ERROR);
        });

        it('resets the doc to orginal state', async () => {
          const expectedDoc = doc(p(''));

          tiptapEditor.commands.uploadImage({ file: validFile });

          await waitForPromises();

          expect(eq(tiptapEditor.state.doc, expectedDoc)).toBe(true);
        });

        it('emits an error event that includes an error message', (done) => {
          tiptapEditor.commands.uploadImage({ file: validFile });

          tiptapEditor.on('error', (message) => {
            expect(message).toBe('An error occurred while uploading the image. Please try again.');
            done();
          });
        });
      });
    });

    describe('when file does not have correct mime type', () => {
      let initialDoc;

      beforeEach(() => {
        initialDoc = doc(p(''));
        tiptapEditor.commands.setContent(initialDoc.toJSON());
      });

      it('does not start the upload image process', () => {
        tiptapEditor.commands.uploadImage({ file: invalidFile });

        expect(eq(tiptapEditor.state.doc, initialDoc)).toBe(true);
      });
    });
  });
});
