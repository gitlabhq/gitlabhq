import fs from 'fs';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { builders } from 'prosemirror-test-builder';
import Attachment from '~/content_editor/extensions/attachment';
import DrawioDiagram from '~/content_editor/extensions/drawio_diagram';
import Image from '~/content_editor/extensions/image';
import Audio from '~/content_editor/extensions/audio';
import Video from '~/content_editor/extensions/video';
import Link from '~/content_editor/extensions/link';
import { VARIANT_DANGER } from '~/alert';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import eventHubFactory from '~/helpers/event_hub_factory';
import { createTestEditor, expectDocumentAfterTransaction } from '../test_utils';
import {
  PROJECT_WIKI_ATTACHMENT_IMAGE_HTML,
  PROJECT_WIKI_ATTACHMENT_IMAGE_SVG_HTML,
  PROJECT_WIKI_ATTACHMENT_AUDIO_HTML,
  PROJECT_WIKI_ATTACHMENT_VIDEO_HTML,
  PROJECT_WIKI_ATTACHMENT_LINK_HTML,
  PROJECT_WIKI_ATTACHMENT_DRAWIO_DIAGRAM_HTML,
} from '../test_constants';

const retinaImage = fs.readFileSync('spec/fixtures/retina_image.png');
const retinaImageSize = { width: 663, height: 325 };

describe('content_editor/extensions/attachment', () => {
  let tiptapEditor;
  let doc;
  let p;
  let image;
  let audio;
  let drawioDiagram;
  let video;
  let link;
  let renderMarkdown;
  let mock;
  let eventHub;

  const uploadsPath = '/uploads/';
  const imageFile = new File(['foo'], 'test-file.png', { type: 'image/png' });
  const imageFileRetina = new File([retinaImage], 'test-file.png', { type: 'image/png' });
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
    renderMarkdown = jest.fn();
    eventHub = eventHubFactory();

    tiptapEditor = createTestEditor({
      extensions: [
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
                src: blobUrl,
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
          const expectedDoc = doc(
            p(
              image({
                uploading: false,
                src: blobUrl,
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
                  src: blobUrl,
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
                  src: blobUrl,
                  canonicalSrc: 'test-file.png',
                  uploading: false,
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: blobUrl,
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
                  src: blobUrl,
                  canonicalSrc: 'test-file.png',
                  uploading: false,
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: blobUrl,
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
                  src: blobUrl,
                  canonicalSrc: 'test-file.png',
                  uploading: false,
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: blobUrl,
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
                  src: blobUrl,
                  canonicalSrc: 'test-file.png',
                  uploading: false,
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: blobUrl,
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
                  src: blobUrl,
                  canonicalSrc: 'test-file.png',
                  uploading: false,
                }),
              ),
              p(
                video({
                  alt: 'test-file.mp4',
                  src: blobUrl,
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
                  canonicalSrc: 'test-file1.mp4',
                  uploading: false,
                }),
              ),
              p(
                audio({
                  alt: 'test-file.mp3',
                  src: blobUrl,
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
  });
});
