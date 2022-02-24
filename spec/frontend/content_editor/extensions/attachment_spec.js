import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Attachment from '~/content_editor/extensions/attachment';
import Image from '~/content_editor/extensions/image';
import Link from '~/content_editor/extensions/link';
import Loading from '~/content_editor/extensions/loading';
import httpStatus from '~/lib/utils/http_status';
import eventHubFactory from '~/helpers/event_hub_factory';
import { createTestEditor, createDocBuilder } from '../test_utils';

const PROJECT_WIKI_ATTACHMENT_IMAGE_HTML = `<p data-sourcepos="1:1-1:27" dir="auto">
  <a class="no-attachment-icon" href="/group1/project1/-/wikis/test-file.png" target="_blank" rel="noopener noreferrer" data-canonical-src="test-file.png">
    <img alt="test-file" class="lazy" data-src="/group1/project1/-/wikis/test-file.png" data-canonical-src="test-file.png">
  </a>
</p>`;
const PROJECT_WIKI_ATTACHMENT_LINK_HTML = `<p data-sourcepos="1:1-1:26" dir="auto">
  <a href="/group1/project1/-/wikis/test-file.zip" data-canonical-src="test-file.zip">test-file</a>
</p>`;

describe('content_editor/extensions/attachment', () => {
  let tiptapEditor;
  let doc;
  let p;
  let image;
  let loading;
  let link;
  let renderMarkdown;
  let mock;
  let eventHub;

  const uploadsPath = '/uploads/';
  const imageFile = new File(['foo'], 'test-file.png', { type: 'image/png' });
  const attachmentFile = new File(['foo'], 'test-file.zip', { type: 'application/zip' });

  const expectDocumentAfterTransaction = ({ number, expectedDoc, action }) => {
    return new Promise((resolve) => {
      let counter = 1;
      const handleTransaction = () => {
        if (counter === number) {
          expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
          tiptapEditor.off('update', handleTransaction);
          resolve();
        }

        counter += 1;
      };

      tiptapEditor.on('update', handleTransaction);
      action();
    });
  };

  beforeEach(() => {
    renderMarkdown = jest.fn();
    eventHub = eventHubFactory();

    tiptapEditor = createTestEditor({
      extensions: [
        Loading,
        Link,
        Image,
        Attachment.configure({ renderMarkdown, uploadsPath, eventHub }),
      ],
    });

    ({
      builders: { doc, p, image, loading, link },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        loading: { markType: Loading.name },
        image: { nodeType: Image.name },
        link: { nodeType: Link.name },
      },
    }));

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.reset();
  });

  it.each`
    eventType  | propName         | eventData                                                             | output
    ${'paste'} | ${'handlePaste'} | ${{ clipboardData: { getData: jest.fn(), files: [attachmentFile] } }} | ${true}
    ${'paste'} | ${'handlePaste'} | ${{ clipboardData: { getData: jest.fn(), files: [] } }}               | ${undefined}
    ${'drop'}  | ${'handleDrop'}  | ${{ dataTransfer: { getData: jest.fn(), files: [attachmentFile] } }}  | ${true}
  `('handles $eventType properly', ({ eventType, propName, eventData, output }) => {
    const event = Object.assign(new Event(eventType), eventData);
    const handled = tiptapEditor.view.someProp(propName, (eventHandler) => {
      return eventHandler(tiptapEditor.view, event);
    });

    expect(handled).toBe(output);
  });

  describe('uploadAttachment command', () => {
    let initialDoc;
    beforeEach(() => {
      initialDoc = doc(p(''));
      tiptapEditor.commands.setContent(initialDoc.toJSON());
    });

    describe('when the file has image mime type', () => {
      const base64EncodedFile = 'data:image/png;base64,Zm9v';

      beforeEach(() => {
        renderMarkdown.mockResolvedValue(PROJECT_WIKI_ATTACHMENT_IMAGE_HTML);
      });

      describe('when uploading succeeds', () => {
        const successResponse = {
          link: {
            markdown: '![test-file](test-file.png)',
          },
        };

        beforeEach(() => {
          mock.onPost().reply(httpStatus.OK, successResponse);
        });

        it('inserts an image with src set to the encoded image file and uploading true', async () => {
          const expectedDoc = doc(p(image({ uploading: true, src: base64EncodedFile })));

          await expectDocumentAfterTransaction({
            number: 1,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file: imageFile }),
          });
        });

        it('updates the inserted image with canonicalSrc when upload is successful', async () => {
          const expectedDoc = doc(
            p(
              image({
                canonicalSrc: 'test-file.png',
                src: base64EncodedFile,
                alt: 'test-file',
                uploading: false,
              }),
            ),
          );

          await expectDocumentAfterTransaction({
            number: 2,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file: imageFile }),
          });
        });
      });

      describe('when uploading request fails', () => {
        beforeEach(() => {
          mock.onPost().reply(httpStatus.INTERNAL_SERVER_ERROR);
        });

        it('resets the doc to original state', async () => {
          const expectedDoc = doc(p(''));

          await expectDocumentAfterTransaction({
            number: 2,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file: imageFile }),
          });
        });

        it('emits an alert event that includes an error message', (done) => {
          tiptapEditor.commands.uploadAttachment({ file: imageFile });

          eventHub.$on('alert', ({ message }) => {
            expect(message).toBe('An error occurred while uploading the image. Please try again.');
            done();
          });
        });
      });
    });

    describe('when the file has a zip (or any other attachment) mime type', () => {
      const markdownApiResult = PROJECT_WIKI_ATTACHMENT_LINK_HTML;

      beforeEach(() => {
        renderMarkdown.mockResolvedValue(markdownApiResult);
      });

      describe('when uploading succeeds', () => {
        const successResponse = {
          link: {
            markdown: '[test-file](test-file.zip)',
          },
        };

        beforeEach(() => {
          mock.onPost().reply(httpStatus.OK, successResponse);
        });

        it('inserts a loading mark', async () => {
          const expectedDoc = doc(p(loading({ label: 'test-file' })));

          await expectDocumentAfterTransaction({
            number: 1,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file: attachmentFile }),
          });
        });

        it('updates the loading mark with a link with canonicalSrc and href attrs', async () => {
          const [, group, project] = markdownApiResult.match(/\/(group[0-9]+)\/(project[0-9]+)\//);
          const expectedDoc = doc(
            p(
              link(
                {
                  canonicalSrc: 'test-file.zip',
                  href: `/${group}/${project}/-/wikis/test-file.zip`,
                },
                'test-file',
              ),
            ),
          );

          await expectDocumentAfterTransaction({
            number: 2,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file: attachmentFile }),
          });
        });
      });

      describe('when uploading request fails', () => {
        beforeEach(() => {
          mock.onPost().reply(httpStatus.INTERNAL_SERVER_ERROR);
        });

        it('resets the doc to orginal state', async () => {
          const expectedDoc = doc(p(''));

          await expectDocumentAfterTransaction({
            number: 2,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file: attachmentFile }),
          });
        });

        it('emits an alert event that includes an error message', (done) => {
          tiptapEditor.commands.uploadAttachment({ file: attachmentFile });

          eventHub.$on('alert', ({ message }) => {
            expect(message).toBe('An error occurred while uploading the file. Please try again.');
            done();
          });
        });
      });
    });
  });
});
