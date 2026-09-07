import MockAdapter from 'axios-mock-adapter';
import { builders } from 'prosemirror-test-builder';
import axios from '~/lib/utils/axios_utils';
import Attachment from '~/content_editor/extensions/attachment';
import Bold from '~/content_editor/extensions/bold';
import DrawioDiagram from '~/content_editor/extensions/drawio_diagram';
import Image from '~/content_editor/extensions/image';
import Audio from '~/content_editor/extensions/audio';
import Video from '~/content_editor/extensions/video';
import Link from '~/content_editor/extensions/link';
import { VARIANT_DANGER } from '~/alert';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import eventHubFactory from '~/helpers/event_hub_factory';
import waitForPromises from 'helpers/wait_for_promises';
import { getLimitedMediaDimensions } from '~/lib/utils/media_utils';
import { createTestEditor, expectDocumentAfterTransaction } from '../test_utils';
import {
  PROJECT_WIKI_ATTACHMENT_IMAGE_HTML,
  PROJECT_WIKI_ATTACHMENT_IMAGE_SVG_HTML,
  PROJECT_WIKI_ATTACHMENT_AUDIO_HTML,
  PROJECT_WIKI_ATTACHMENT_VIDEO_HTML,
  PROJECT_WIKI_ATTACHMENT_LINK_HTML,
  PROJECT_WIKI_ATTACHMENT_DRAWIO_DIAGRAM_HTML,
} from '../test_constants';

const retinaImageSize = { width: 663, height: 325 };

jest.mock('~/lib/utils/media_utils');

describe('content_editor/extensions/attachment', () => {
  let tiptapEditor;
  let doc;
  let p;
  let image;
  let audio;
  let bold;
  let drawioDiagram;
  let video;
  let link;
  let renderMarkdown;
  let mock;
  let eventHub;

  const uploadsPath = '/uploads/';
  const imageFile = new File(['foo'], 'test-file.png', { type: 'image/png' });
  const imageFileRetina = new File(['foo'], 'test-file.png', { type: 'image/png' });
  const imageFileSvg = new File(['foo'], 'test-file.svg', { type: 'image/svg+xml' });
  const audioFile = new File(['foo'], 'test-file.mp3', { type: 'audio/mpeg' });
  const videoFile = new File(['foo'], 'test-file.mp4', { type: 'video/mp4' });
  const videoFile1 = new File(['foo'], 'test-file1.mp4', { type: 'video/mp4' });
  const drawioDiagramFile = new File(['foo'], 'test-file.drawio.svg', { type: 'image/svg+xml' });
  const attachmentFile = new File(['foo'], 'test-file.zip', { type: 'application/zip' });
  const attachmentFile1 = new File(['foo'], 'test-file1.zip', { type: 'application/zip' });
  const attachmentFile2 = new File(['foo'], 'test-file2.zip', { type: 'application/zip' });

  const markdownApiResult = {
    'test-file.png': PROJECT_WIKI_ATTACHMENT_IMAGE_HTML,
    'test-file.svg': PROJECT_WIKI_ATTACHMENT_IMAGE_SVG_HTML,
    'test-file.mp3': PROJECT_WIKI_ATTACHMENT_AUDIO_HTML,
    'test-file.mp4': PROJECT_WIKI_ATTACHMENT_VIDEO_HTML,
    'test-file1.mp4': PROJECT_WIKI_ATTACHMENT_VIDEO_HTML.replace(/test-file/g, 'test-file1'),
    'test-file.zip': PROJECT_WIKI_ATTACHMENT_LINK_HTML,
    'test-file1.zip': PROJECT_WIKI_ATTACHMENT_LINK_HTML.replace(/test-file/g, 'test-file1'),
    'test-file2.zip': PROJECT_WIKI_ATTACHMENT_LINK_HTML.replace(/test-file/g, 'test-file2'),
    'test-file.drawio.svg': PROJECT_WIKI_ATTACHMENT_DRAWIO_DIAGRAM_HTML,
  };

  const [, group, project] = markdownApiResult[attachmentFile.name].match(
    /\/(group[0-9]+)\/(project[0-9]+)\//,
  );
  const blobUrl = 'blob:https://gitlab.com/048c7ac1-98de-4a37-ab1b-0206d0ea7e1b';

  beforeEach(() => {
    getLimitedMediaDimensions.mockResolvedValue(null);
    renderMarkdown = jest.fn();
    eventHub = eventHubFactory();

    tiptapEditor = createTestEditor({
      extensions: [
        Bold,
        Link,
        Image,
        Audio,
        Video,
        DrawioDiagram,
        Attachment.configure({ renderMarkdown, uploadsPath, eventHub }),
      ],
    });

    ({
      doc,
      paragraph: p,
      image,
      audio,
      bold,
      video,
      link,
      drawioDiagram,
    } = builders(tiptapEditor.schema));

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
    mock.onPost().reply(HTTP_STATUS_OK, {
      link: {
        markdown: `![test-file](test-file.png)`,
      },
    });

    renderMarkdown.mockResolvedValue({ body: PROJECT_WIKI_ATTACHMENT_IMAGE_HTML });

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

    describe.each`
      nodeType           | html                                           | file                 | mediaType
      ${'image'}         | ${PROJECT_WIKI_ATTACHMENT_IMAGE_HTML}          | ${imageFile}         | ${(attrs) => image(attrs)}
      ${'image'}         | ${PROJECT_WIKI_ATTACHMENT_IMAGE_SVG_HTML}      | ${imageFileSvg}      | ${(attrs) => image(attrs)}
      ${'audio'}         | ${PROJECT_WIKI_ATTACHMENT_AUDIO_HTML}          | ${audioFile}         | ${(attrs) => audio(attrs)}
      ${'video'}         | ${PROJECT_WIKI_ATTACHMENT_VIDEO_HTML}          | ${videoFile}         | ${(attrs) => video(attrs)}
      ${'drawioDiagram'} | ${PROJECT_WIKI_ATTACHMENT_DRAWIO_DIAGRAM_HTML} | ${drawioDiagramFile} | ${(attrs) => drawioDiagram(attrs)}
    `('when the file is $nodeType', ({ nodeType, html, file, mediaType }) => {
      beforeEach(() => {
        renderMarkdown.mockResolvedValue({ body: html });
      });

      describe('when uploading succeeds', () => {
        const successResponse = {
          link: {
            markdown: `![test-file](${file.name})`,
          },
        };

        beforeEach(() => {
          mock.onPost().reply(HTTP_STATUS_OK, successResponse);
        });

        it('inserts a media content with src set to the encoded content and uploading=file_name', async () => {
          const expectedDoc = doc(
            p(
              mediaType({
                uploading: expect.stringMatching(new RegExp(`${nodeType}[0-9]+`)),
                src: blobUrl,
                alt: file.name,
              }),
            ),
          );

          await expectDocumentAfterTransaction({
            tiptapEditor,
            number: 1,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file }),
          });
        });

        it('updates the inserted content with canonicalSrc when upload is successful', async () => {
          const expectedDoc = doc(
            p(
              mediaType({
                canonicalSrc: file.name,
                src: `/${group}/${project}/-/wikis/${file.name}`,
                alt: expect.stringContaining('test-file'),
                uploading: false,
              }),
            ),
          );

          await expectDocumentAfterTransaction({
            tiptapEditor,
            number: 2,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file }),
          });
        });
      });

      describe('when uploading a large file', () => {
        beforeEach(() => {
          // Set max file size to 1 byte, our file is 3 bytes
          gon.max_file_size = 1 / 1024 / 1024;
        });

        it('emits an alert event that includes an error message', () => {
          tiptapEditor.commands.uploadAttachment({ file });

          return new Promise((resolve) => {
            eventHub.$on('alert', ({ message, variant }) => {
              expect(variant).toBe(VARIANT_DANGER);
              expect(message).toContain('File is too big');
              resolve();
            });
          });
        });
      });

      describe('when uploading request fails', () => {
        beforeEach(() => {
          mock.onPost().reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        });

        it('resets the doc to original state', async () => {
          const expectedDoc = doc(p(''));

          await expectDocumentAfterTransaction({
            tiptapEditor,
            number: 2,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file }),
          });
        });

        it('emits an alert event that includes an error message', () => {
          tiptapEditor.commands.uploadAttachment({ file });

          return new Promise((resolve) => {
            eventHub.$on('alert', ({ message, variant }) => {
              expect(variant).toBe(VARIANT_DANGER);
              expect(message).toBe('An error occurred while uploading the file. Please try again.');
              resolve();
            });
          });
        });
      });
    });

    describe('when the file is a retina image', () => {
      beforeEach(() => {
        renderMarkdown.mockResolvedValue({ body: PROJECT_WIKI_ATTACHMENT_IMAGE_HTML });
      });

      describe('when uploading succeeds', () => {
        const successResponse = {
          link: {
            markdown: `![test-file](${imageFileRetina.name})`,
          },
        };

        beforeEach(() => {
          mock.onPost().reply(HTTP_STATUS_OK, successResponse);
        });

        it('updates the image with width and height if available', async () => {
          getLimitedMediaDimensions.mockResolvedValue(retinaImageSize);
          const expectedDoc = doc(
            p(
              image({
                uploading: false,
                src: `/${group}/${project}/-/wikis/${imageFileRetina.name}`,
                alt: imageFileRetina.name,
                canonicalSrc: imageFileRetina.name,
                ...retinaImageSize,
              }),
            ),
          );

          await expectDocumentAfterTransaction({
            tiptapEditor,
            number: 3,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file: imageFileRetina }),
          });
        });
      });
    });

    describe('when the file has a zip (or any other attachment) mime type', () => {
      beforeEach(() => {
        renderMarkdown.mockResolvedValue({ body: markdownApiResult[attachmentFile.name] });
      });

      describe('when uploading succeeds', () => {
        const successResponse = {
          link: {
            markdown: '[test-file](test-file.zip)',
          },
        };

        beforeEach(() => {
          mock.onPost().reply(HTTP_STATUS_OK, successResponse);
        });

        it('inserts a link with a blob url', async () => {
          const expectedDoc = doc(
            p(
              link(
                { uploading: expect.stringMatching(/file[0-9]+/), href: blobUrl },
                'test-file.zip',
              ),
            ),
          );

          await expectDocumentAfterTransaction({
            tiptapEditor,
            number: 1,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file: attachmentFile }),
          });
        });

        it('updates the blob url link with an actual link with canonicalSrc and href attrs', async () => {
          const expectedDoc = doc(
            p(
              link(
                {
                  canonicalSrc: 'test-file.zip',
                  href: `/${group}/${project}/-/wikis/test-file.zip`,
                },
                'test-file.zip',
              ),
            ),
          );

          await expectDocumentAfterTransaction({
            tiptapEditor,
            number: 2,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file: attachmentFile }),
          });
        });
      });

      describe('when uploading request fails', () => {
        beforeEach(() => {
          mock.onPost().reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        });

        it('resets the doc to orginal state', async () => {
          const expectedDoc = doc(p(''));

          await expectDocumentAfterTransaction({
            tiptapEditor,
            number: 2,
            expectedDoc,
            action: () => tiptapEditor.commands.uploadAttachment({ file: attachmentFile }),
          });
        });

        it('emits an alert event that includes an error message', () => {
          tiptapEditor.commands.uploadAttachment({ file: attachmentFile });

          eventHub.$on('alert', ({ message, variant }) => {
            expect(variant).toBe(VARIANT_DANGER);
            expect(message).toBe('An error occurred while uploading the file. Please try again.');
          });
        });
      });
    });

    describe('uploading multiple files', () => {
      const uploadMultipleFiles = () => {
        const files = [
          attachmentFile,
          imageFile,
          videoFile,
          attachmentFile1,
          attachmentFile2,
          videoFile1,
          audioFile,
        ];

        for (const file of files) {
          renderMarkdown.mockImplementation((markdown) =>
            Promise.resolve({ body: markdownApiResult[markdown.match(/\((.+?)\)$/)[1]] }),
          );

          mock
            .onPost()
            .replyOnce(HTTP_STATUS_OK, { link: { markdown: `![test-file](${file.name})` } });

          tiptapEditor.commands.uploadAttachment({ file });
        }
      };

      it.each([
        [
          1,
          () =>
            doc(
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file.zip',
                ),
              ),
            ),
        ],
        [
          2,
          () =>
            doc(
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: blobUrl,
                  uploading: expect.stringMatching(/image[0-9]+/),
                }),
              ),
            ),
        ],
        [
          3,
          () =>
            doc(
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: blobUrl,
                  uploading: expect.stringMatching(/image[0-9]+/),
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
            ),
        ],
        [
          4,
          () =>
            doc(
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: blobUrl,
                  uploading: expect.stringMatching(/image[0-9]+/),
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file1.zip',
                ),
              ),
            ),
        ],
        [
          5,
          () =>
            doc(
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: blobUrl,
                  uploading: expect.stringMatching(/image[0-9]+/),
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file1.zip',
                ),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file2.zip',
                ),
              ),
            ),
        ],
        [
          6,
          () =>
            doc(
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: blobUrl,
                  uploading: expect.stringMatching(/image[0-9]+/),
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file1.zip',
                ),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file2.zip',
                ),
              ),
              p(
                video({
                  alt: 'test-file1.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
            ),
        ],
        [
          7,
          () =>
            doc(
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: blobUrl,
                  uploading: expect.stringMatching(/image[0-9]+/),
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file1.zip',
                ),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file2.zip',
                ),
              ),
              p(
                video({
                  alt: 'test-file1.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
              p(
                audio({
                  alt: 'test-file.mp3',
                  src: blobUrl,
                  uploading: expect.stringMatching(/audio[0-9]+/),
                }),
              ),
            ),
        ],
        [
          8,
          () =>
            doc(
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file.zip`,
                    canonicalSrc: 'test-file.zip',
                    uploading: false,
                  },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: blobUrl,
                  uploading: expect.stringMatching(/image[0-9]+/),
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file1.zip',
                ),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file2.zip',
                ),
              ),
              p(
                video({
                  alt: 'test-file1.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
              p(
                audio({
                  alt: 'test-file.mp3',
                  src: blobUrl,
                  uploading: expect.stringMatching(/audio[0-9]+/),
                }),
              ),
            ),
        ],
        [
          9,
          () =>
            doc(
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file.zip`,
                    canonicalSrc: 'test-file.zip',
                    uploading: false,
                  },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: `/${group}/${project}/-/wikis/test-file.png`,
                  canonicalSrc: 'test-file.png',
                  uploading: false,
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file1.zip',
                ),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file2.zip',
                ),
              ),
              p(
                video({
                  alt: 'test-file1.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
              p(
                audio({
                  alt: 'test-file.mp3',
                  src: blobUrl,
                  uploading: expect.stringMatching(/audio[0-9]+/),
                }),
              ),
            ),
        ],
        [
          10,
          () =>
            doc(
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file.zip`,
                    canonicalSrc: 'test-file.zip',
                    uploading: false,
                  },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: `/${group}/${project}/-/wikis/test-file.png`,
                  canonicalSrc: 'test-file.png',
                  uploading: false,
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: `/${group}/${project}/-/wikis/test-file.mp4`,
                  canonicalSrc: 'test-file.mp4',
                  uploading: false,
                }),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file1.zip',
                ),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file2.zip',
                ),
              ),
              p(
                video({
                  alt: 'test-file1.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
              p(
                audio({
                  alt: 'test-file.mp3',
                  src: blobUrl,
                  uploading: expect.stringMatching(/audio[0-9]+/),
                }),
              ),
            ),
        ],
        [
          11,
          () =>
            doc(
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file.zip`,
                    canonicalSrc: 'test-file.zip',
                    uploading: false,
                  },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: `/${group}/${project}/-/wikis/test-file.png`,
                  canonicalSrc: 'test-file.png',
                  uploading: false,
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: `/${group}/${project}/-/wikis/test-file.mp4`,
                  canonicalSrc: 'test-file.mp4',
                  uploading: false,
                }),
              ),
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file1.zip`,
                    canonicalSrc: 'test-file1.zip',
                    uploading: false,
                  },
                  'test-file1.zip',
                ),
              ),
              p(
                link(
                  { href: blobUrl, uploading: expect.stringMatching(/file[0-9]+/) },
                  'test-file2.zip',
                ),
              ),
              p(
                video({
                  alt: 'test-file1.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
              p(
                audio({
                  alt: 'test-file.mp3',
                  src: blobUrl,
                  uploading: expect.stringMatching(/audio[0-9]+/),
                }),
              ),
            ),
        ],
        [
          12,
          () =>
            doc(
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file.zip`,
                    canonicalSrc: 'test-file.zip',
                    uploading: false,
                  },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: `/${group}/${project}/-/wikis/test-file.png`,
                  canonicalSrc: 'test-file.png',
                  uploading: false,
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: `/${group}/${project}/-/wikis/test-file.mp4`,
                  canonicalSrc: 'test-file.mp4',
                  uploading: false,
                }),
              ),
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file1.zip`,
                    canonicalSrc: 'test-file1.zip',
                    uploading: false,
                  },
                  'test-file1.zip',
                ),
              ),
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file2.zip`,
                    canonicalSrc: 'test-file2.zip',
                    uploading: false,
                  },
                  'test-file2.zip',
                ),
              ),
              p(
                video({
                  alt: 'test-file1.mp4',
                  src: blobUrl,
                  uploading: expect.stringMatching(/video[0-9]+/),
                }),
              ),
              p(
                audio({
                  alt: 'test-file.mp3',
                  src: blobUrl,
                  uploading: expect.stringMatching(/audio[0-9]+/),
                }),
              ),
            ),
        ],
        [
          13,
          () =>
            doc(
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file.zip`,
                    canonicalSrc: 'test-file.zip',
                    uploading: false,
                  },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: `/${group}/${project}/-/wikis/test-file.png`,
                  canonicalSrc: 'test-file.png',
                  uploading: false,
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: `/${group}/${project}/-/wikis/test-file.mp4`,
                  canonicalSrc: 'test-file.mp4',
                  uploading: false,
                }),
              ),
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file1.zip`,
                    canonicalSrc: 'test-file1.zip',
                    uploading: false,
                  },
                  'test-file1.zip',
                ),
              ),
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file2.zip`,
                    canonicalSrc: 'test-file2.zip',
                    uploading: false,
                  },
                  'test-file2.zip',
                ),
              ),
              p(
                video({
                  alt: 'test-file1.mp4',
                  src: `/${group}/${project}/-/wikis/test-file1.mp4`,
                  canonicalSrc: 'test-file1.mp4',
                  uploading: false,
                }),
              ),
              p(
                audio({
                  alt: 'test-file.mp3',
                  src: blobUrl,
                  uploading: expect.stringMatching(/audio[0-9]+/),
                }),
              ),
            ),
        ],
        [
          14,
          () =>
            doc(
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file.zip`,
                    canonicalSrc: 'test-file.zip',
                    uploading: false,
                  },
                  'test-file.zip',
                ),
              ),
              p(
                image({
                  alt: 'test-file.png',
                  src: `/${group}/${project}/-/wikis/test-file.png`,
                  canonicalSrc: 'test-file.png',
                  uploading: false,
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: `/${group}/${project}/-/wikis/test-file.mp4`,
                  canonicalSrc: 'test-file.mp4',
                  uploading: false,
                }),
              ),
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file1.zip`,
                    canonicalSrc: 'test-file1.zip',
                    uploading: false,
                  },
                  'test-file1.zip',
                ),
              ),
              p(
                link(
                  {
                    href: `/${group}/${project}/-/wikis/test-file2.zip`,
                    canonicalSrc: 'test-file2.zip',
                    uploading: false,
                  },
                  'test-file2.zip',
                ),
              ),
              p(
                video({
                  alt: 'test-file1.mp4',
                  src: `/${group}/${project}/-/wikis/test-file1.mp4`,
                  canonicalSrc: 'test-file1.mp4',
                  uploading: false,
                }),
              ),
              p(
                audio({
                  alt: 'test-file.mp3',
                  src: `/${group}/${project}/-/wikis/test-file.mp3`,
                  canonicalSrc: 'test-file.mp3',
                  uploading: false,
                }),
              ),
            ),
        ],
      ])('uploads all files of mixed types successfully (tx %i)', async (n, document) => {
        await expectDocumentAfterTransaction({
          tiptapEditor,
          number: n,
          expectedDoc: document(),
          action: uploadMultipleFiles,
        });
      });

      it('cleans up the state if all uploads fail', async () => {
        await expectDocumentAfterTransaction({
          tiptapEditor,
          number: 14,
          expectedDoc: doc(p(), p(), p(), p(), p(), p(), p()),
          action: () => {
            // Set max file size to 1 byte, our file is 3 bytes
            gon.max_file_size = 1 / 1024 / 1024;
            uploadMultipleFiles();
          },
        });
      });
    });

    describe('when a second media file is added before the first reports its dimensions', () => {
      it('applies dimensions to each media node individually', async () => {
        const firstDimensions = { width: 100, height: 80 };
        const secondDimensions = { width: 200, height: 160 };

        // Keep both uploads in flight (renderMarkdown unresolved) so each node
        // retains its uploading marker while the dimension lookups resolve.
        let completeUploads;
        renderMarkdown.mockReturnValue(
          new Promise((resolve) => {
            completeUploads = resolve;
          }),
        );
        mock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: '![test-file](test-file.png)' } });

        let resolveFirstDimensions;
        let resolveSecondDimensions;
        getLimitedMediaDimensions
          .mockReturnValueOnce(
            new Promise((resolve) => {
              resolveFirstDimensions = resolve;
            }),
          )
          .mockReturnValueOnce(
            new Promise((resolve) => {
              resolveSecondDimensions = resolve;
            }),
          );

        tiptapEditor.commands.uploadAttachment({ file: imageFile });
        await waitForPromises();
        tiptapEditor.commands.uploadAttachment({ file: imageFileRetina });
        await waitForPromises();

        // The second image is now selected, but the first image's dimensions
        // resolve last. They must still land on the first image.
        resolveSecondDimensions(secondDimensions);
        resolveFirstDimensions(firstDimensions);
        await waitForPromises();

        const images = [];
        tiptapEditor.state.doc.descendants((node) => {
          if (node.type.name === 'image') images.push(node.attrs);
          return true;
        });

        expect(images).toHaveLength(2);
        expect(images[0]).toMatchObject(firstDimensions);
        expect(images[1]).toMatchObject(secondDimensions);

        completeUploads({ body: PROJECT_WIKI_ATTACHMENT_IMAGE_HTML });
        await waitForPromises();
      });

      it('applies dimensions to the node even after the cursor moves away', async () => {
        const dimensions = { width: 100, height: 80 };

        // Keep the upload in flight so the node retains its uploading marker
        // while the dimension lookup resolves.
        let completeUpload;
        renderMarkdown.mockReturnValue(
          new Promise((resolve) => {
            completeUpload = resolve;
          }),
        );
        mock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: '![test-file](test-file.png)' } });

        let resolveDimensions;
        getLimitedMediaDimensions.mockReturnValueOnce(
          new Promise((resolve) => {
            resolveDimensions = resolve;
          }),
        );

        tiptapEditor.commands.uploadAttachment({ file: imageFile });
        await waitForPromises();

        // The user clicks elsewhere before the image's dimensions resolve.
        tiptapEditor.commands.setTextSelection(0);

        resolveDimensions(dimensions);
        await waitForPromises();

        let imageAttrs;
        tiptapEditor.state.doc.descendants((node) => {
          if (node.type.name === 'image') imageAttrs = node.attrs;
          return true;
        });

        expect(imageAttrs).toMatchObject(dimensions);

        completeUpload({ body: PROJECT_WIKI_ATTACHMENT_IMAGE_HTML });
        await waitForPromises();
      });
    });

    describe('when the user moves the selection while a file is uploading', () => {
      let completeUpload;
      let rejectUpload;
      let alertSpy;

      const uploadedImageAttrs = {
        alt: 'test-file.png',
        canonicalSrc: 'test-file.png',
        src: `/${group}/${project}/-/wikis/test-file.png`,
        uploading: false,
      };

      const startUploadAndMoveCaret = async (file) => {
        renderMarkdown.mockReturnValue(
          new Promise((resolve, reject) => {
            completeUpload = resolve;
            rejectUpload = reject;
          }),
        );
        mock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: `![test-file](${file.name})` } });

        tiptapEditor.commands.setContent(doc(p('hello')).toJSON());
        tiptapEditor.commands.setTextSelection(6);
        tiptapEditor.commands.uploadAttachment({ file });
        await waitForPromises();

        // the user moves the caret back into the text while the upload is in flight
        tiptapEditor.commands.setTextSelection(3);
      };

      beforeEach(() => {
        alertSpy = jest.fn();
        eventHub.$on('alert', alertSpy);
      });

      describe('when a media upload succeeds', () => {
        beforeEach(async () => {
          await startUploadAndMoveCaret(imageFile);

          completeUpload({ body: PROJECT_WIKI_ATTACHMENT_IMAGE_HTML });
          await waitForPromises();
        });

        it('updates the media node without moving the selection', () => {
          expect(tiptapEditor.state.doc.toJSON()).toEqual(
            doc(p('hello'), p(image(uploadedImageAttrs))).toJSON(),
          );
          expect(tiptapEditor.state.selection.toJSON()).toEqual({
            type: 'text',
            anchor: 3,
            head: 3,
          });
        });

        it('does not replace the media node when the user keeps typing', () => {
          tiptapEditor.commands.insertContent('X');

          expect(tiptapEditor.state.doc.toJSON()).toEqual(
            doc(p('heXllo'), p(image(uploadedImageAttrs))).toJSON(),
          );
        });
      });

      describe('when a media upload fails', () => {
        beforeEach(async () => {
          await startUploadAndMoveCaret(imageFile);

          rejectUpload(new Error('upload failed'));
          await waitForPromises();
        });

        it('removes the media node without moving the selection', () => {
          expect(tiptapEditor.state.doc.toJSON()).toEqual(doc(p('hello'), p()).toJSON());
          expect(tiptapEditor.state.selection.toJSON()).toEqual({
            type: 'text',
            anchor: 3,
            head: 3,
          });
          expect(alertSpy).toHaveBeenCalledWith({
            message: 'An error occurred while uploading the file. Please try again.',
            variant: VARIANT_DANGER,
          });
        });
      });

      describe('when an attachment upload succeeds', () => {
        beforeEach(async () => {
          await startUploadAndMoveCaret(attachmentFile);

          completeUpload({ body: markdownApiResult[attachmentFile.name] });
          await waitForPromises();
        });

        it('updates the link attributes without moving the selection', () => {
          expect(tiptapEditor.state.doc.toJSON()).toEqual(
            doc(
              p('hello'),
              p(
                link(
                  {
                    canonicalSrc: 'test-file.zip',
                    href: `/${group}/${project}/-/wikis/test-file.zip`,
                  },
                  'test-file.zip',
                ),
              ),
            ).toJSON(),
          );
          expect(tiptapEditor.state.selection.toJSON()).toEqual({
            type: 'text',
            anchor: 3,
            head: 3,
          });
        });
      });

      describe('when an attachment upload fails', () => {
        beforeEach(async () => {
          await startUploadAndMoveCaret(attachmentFile);

          rejectUpload(new Error('upload failed'));
          await waitForPromises();
        });

        it('removes the placeholder link without moving the selection', () => {
          expect(tiptapEditor.state.doc.toJSON()).toEqual(doc(p('hello'), p()).toJSON());
          expect(tiptapEditor.state.selection.toJSON()).toEqual({
            type: 'text',
            anchor: 3,
            head: 3,
          });
          expect(alertSpy).toHaveBeenCalledWith({
            message: 'An error occurred while uploading the file. Please try again.',
            variant: VARIANT_DANGER,
          });
        });
      });
    });

    describe('when the selection has not moved during the upload', () => {
      let completeUpload;

      beforeEach(() => {
        renderMarkdown.mockReturnValue(
          new Promise((resolve) => {
            completeUpload = resolve;
          }),
        );
        mock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: '![test-file](test-file.png)' } });
      });

      it('keeps the uploaded media node selected when the upload completes', async () => {
        tiptapEditor.commands.uploadAttachment({ file: imageFile });
        await waitForPromises();

        expect(tiptapEditor.state.selection.toJSON()).toEqual({ type: 'node', anchor: 1 });

        completeUpload({ body: PROJECT_WIKI_ATTACHMENT_IMAGE_HTML });
        await waitForPromises();

        expect(tiptapEditor.state.selection.toJSON()).toEqual({ type: 'node', anchor: 1 });
        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(
            p(
              image({
                alt: 'test-file.png',
                canonicalSrc: 'test-file.png',
                src: `/${group}/${project}/-/wikis/test-file.png`,
                uploading: false,
              }),
            ),
          ).toJSON(),
        );
      });

      it('keeps the media node selected when its dimensions land mid-upload', async () => {
        getLimitedMediaDimensions.mockResolvedValue(retinaImageSize);

        tiptapEditor.commands.uploadAttachment({ file: imageFile });
        await waitForPromises();

        expect(tiptapEditor.state.selection.toJSON()).toEqual({ type: 'node', anchor: 1 });

        completeUpload({ body: PROJECT_WIKI_ATTACHMENT_IMAGE_HTML });
        await waitForPromises();

        expect(tiptapEditor.state.selection.toJSON()).toEqual({ type: 'node', anchor: 1 });
        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(
            p(
              image({
                alt: 'test-file.png',
                canonicalSrc: 'test-file.png',
                src: `/${group}/${project}/-/wikis/test-file.png`,
                uploading: false,
                ...retinaImageSize,
              }),
            ),
          ).toJSON(),
        );
      });

      it('keeps the selection on the uploaded link when the upload completes', async () => {
        completeUpload = null;
        renderMarkdown.mockReturnValue(
          new Promise((resolve) => {
            completeUpload = resolve;
          }),
        );
        mock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: '[test-file](test-file.zip)' } });

        tiptapEditor.commands.uploadAttachment({ file: attachmentFile });
        await waitForPromises();

        expect(tiptapEditor.state.selection.toJSON()).toEqual({
          type: 'text',
          anchor: 1,
          head: 14,
        });

        completeUpload({ body: markdownApiResult[attachmentFile.name] });
        await waitForPromises();

        expect(tiptapEditor.state.selection.toJSON()).toEqual({
          type: 'text',
          anchor: 1,
          head: 14,
        });
      });
    });

    describe('when the placeholder is deleted while the file is uploading', () => {
      let completeUpload;
      let rejectUpload;
      let alertSpy;

      const startUploadAndDeletePlaceholder = async (file) => {
        renderMarkdown.mockReturnValue(
          new Promise((resolve, reject) => {
            completeUpload = resolve;
            rejectUpload = reject;
          }),
        );
        mock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: `![test-file](${file.name})` } });

        tiptapEditor.commands.uploadAttachment({ file });
        await waitForPromises();

        tiptapEditor.commands.clearContent();
      };

      beforeEach(() => {
        alertSpy = jest.fn();
        eventHub.$on('alert', alertSpy);
      });

      describe.each`
        fileType           | file
        ${'a media'}       | ${imageFile}
        ${'an attachment'} | ${attachmentFile}
      `('when $fileType upload succeeds', ({ file }) => {
        beforeEach(async () => {
          await startUploadAndDeletePlaceholder(file);

          completeUpload({ body: markdownApiResult[file.name] });
          await waitForPromises();
          await waitForPromises();
        });

        it('discards the upload result without modifying the document', () => {
          expect(tiptapEditor.state.doc.toJSON()).toEqual(doc(p()).toJSON());
          expect(alertSpy).not.toHaveBeenCalled();
        });
      });

      describe.each`
        fileType           | file
        ${'a media'}       | ${imageFile}
        ${'an attachment'} | ${attachmentFile}
      `('when $fileType upload fails', ({ file }) => {
        beforeEach(async () => {
          await startUploadAndDeletePlaceholder(file);

          rejectUpload(new Error('upload failed'));
          await waitForPromises();
          await waitForPromises();
        });

        it('emits an error alert without modifying the document', () => {
          expect(tiptapEditor.state.doc.toJSON()).toEqual(doc(p()).toJSON());
          expect(alertSpy).toHaveBeenCalledWith({
            message: 'An error occurred while uploading the file. Please try again.',
            variant: VARIANT_DANGER,
          });
        });
      });
    });

    describe('when the uploading link is split by another mark', () => {
      let completeUpload;
      let rejectUpload;
      let alertSpy;

      beforeEach(async () => {
        alertSpy = jest.fn();
        eventHub.$on('alert', alertSpy);

        renderMarkdown.mockReturnValue(
          new Promise((resolve, reject) => {
            completeUpload = resolve;
            rejectUpload = reject;
          }),
        );
        mock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: '[test-file](test-file.zip)' } });

        tiptapEditor.commands.uploadAttachment({ file: attachmentFile });
        await waitForPromises();

        // apply bold to part of the uploading filename to split the link text node
        tiptapEditor.commands.setTextSelection({ from: 6, to: 10 });
        tiptapEditor.commands.setBold();
      });

      describe('when the upload succeeds', () => {
        beforeEach(async () => {
          completeUpload({ body: markdownApiResult[attachmentFile.name] });
          await waitForPromises();
        });

        it('updates every segment of the link', () => {
          const linkAttrs = {
            canonicalSrc: 'test-file.zip',
            href: `/${group}/${project}/-/wikis/test-file.zip`,
          };

          expect(tiptapEditor.state.doc.toJSON()).toEqual(
            doc(
              p(link(linkAttrs, 'test-'), link(linkAttrs, bold('file')), link(linkAttrs, '.zip')),
            ).toJSON(),
          );
        });
      });

      describe('when the upload fails', () => {
        beforeEach(async () => {
          rejectUpload(new Error('upload failed'));
          await waitForPromises();
        });

        it('removes every segment of the link', () => {
          expect(tiptapEditor.state.doc.toJSON()).toEqual(doc(p()).toJSON());
          expect(alertSpy).toHaveBeenCalledWith({
            message: 'An error occurred while uploading the file. Please try again.',
            variant: VARIANT_DANGER,
          });
        });
      });
    });

    describe('when the middle of the uploading link is unlinked', () => {
      let completeUpload;
      let rejectUpload;

      const linkAttrs = {
        canonicalSrc: 'test-file.zip',
        href: `/${group}/${project}/-/wikis/test-file.zip`,
      };

      beforeEach(async () => {
        renderMarkdown.mockReturnValue(
          new Promise((resolve, reject) => {
            completeUpload = resolve;
            rejectUpload = reject;
          }),
        );
        mock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: '[test-file](test-file.zip)' } });

        tiptapEditor.commands.uploadAttachment({ file: attachmentFile });
        await waitForPromises();

        // unlink part of the uploading filename so the placeholder is no longer contiguous
        tiptapEditor.commands.setTextSelection({ from: 6, to: 10 });
        tiptapEditor.commands.unsetLink();
      });

      it('updates both remaining segments when the upload succeeds', async () => {
        completeUpload({ body: markdownApiResult[attachmentFile.name] });
        await waitForPromises();

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(p(link(linkAttrs, 'test-'), 'file', link(linkAttrs, '.zip'))).toJSON(),
        );
      });

      it('removes both remaining segments when the upload fails', async () => {
        rejectUpload(new Error('upload failed'));
        await waitForPromises();

        expect(tiptapEditor.state.doc.toJSON()).toEqual(doc(p('file')).toJSON());
      });
    });

    describe('when the placeholder link is joined onto another link', () => {
      beforeEach(async () => {
        let completeUpload;

        renderMarkdown.mockReturnValue(
          new Promise((resolve) => {
            completeUpload = resolve;
          }),
        );
        mock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: '[test-file](test-file.zip)' } });

        tiptapEditor.commands.setContent(
          doc(p(link({ href: 'https://example.com' }, 'foo'))).toJSON(),
        );
        tiptapEditor.commands.setTextSelection(4);
        tiptapEditor.commands.uploadAttachment({ file: attachmentFile });
        await waitForPromises();

        // backspace at the start of the placeholder paragraph joins it onto the previous link
        tiptapEditor.view.dispatch(tiptapEditor.state.tr.join(5));

        completeUpload({ body: markdownApiResult[attachmentFile.name] });
        await waitForPromises();
      });

      it('updates the placeholder link without touching its neighbor', () => {
        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(
            p(
              link({ href: 'https://example.com' }, 'foo'),
              link(
                {
                  canonicalSrc: 'test-file.zip',
                  href: `/${group}/${project}/-/wikis/test-file.zip`,
                },
                'test-file.zip',
              ),
            ),
          ).toJSON(),
        );
      });
    });

    describe('when the uploading media node was duplicated', () => {
      let completeUpload;
      let rejectUpload;

      const uploadedImageAttrs = {
        alt: 'test-file.png',
        canonicalSrc: 'test-file.png',
        src: `/${group}/${project}/-/wikis/test-file.png`,
        uploading: false,
      };

      beforeEach(async () => {
        renderMarkdown.mockReturnValue(
          new Promise((resolve, reject) => {
            completeUpload = resolve;
            rejectUpload = reject;
          }),
        );
        mock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: '![test-file](test-file.png)' } });

        tiptapEditor.commands.uploadAttachment({ file: imageFile });
        await waitForPromises();

        // copies share the node instance (as on a drag that copies); select the first copy
        const placeholder = tiptapEditor.state.doc.nodeAt(1);
        tiptapEditor.view.dispatch(tiptapEditor.state.tr.insert(2, placeholder));
        tiptapEditor.commands.setNodeSelection(1);
      });

      describe('when the upload succeeds', () => {
        beforeEach(async () => {
          completeUpload({ body: PROJECT_WIKI_ATTACHMENT_IMAGE_HTML });
          await waitForPromises();
        });

        it('completes every copy', () => {
          expect(tiptapEditor.state.doc.toJSON()).toEqual(
            doc(p(image(uploadedImageAttrs), image(uploadedImageAttrs))).toJSON(),
          );
        });

        it('keeps the selection on the selected copy', () => {
          expect(tiptapEditor.state.selection.toJSON()).toEqual({ type: 'node', anchor: 1 });
        });
      });

      describe('when the upload fails', () => {
        beforeEach(async () => {
          rejectUpload(new Error('upload failed'));
          await waitForPromises();
        });

        it('removes every copy', () => {
          expect(tiptapEditor.state.doc.toJSON()).toEqual(doc(p()).toJSON());
        });
      });
    });
  });
});
