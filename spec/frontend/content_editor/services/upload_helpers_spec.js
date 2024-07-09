import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { uploadFile } from '~/content_editor/services/upload_helpers';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('content_editor/services/upload_helpers', () => {
  const uploadsPath = '/uploads';
  const file = new File(['content'], 'file.txt');
  // TODO: Replace with automated fixture
  const renderedAttachmentLinkFixture =
    '<a href="/group1/project1/-/wikis/test-file.png" data-canonical-src="test-file.png"><img data-src="/group1/project1/-/wikis/test-file.png" data-canonical-src="test-file.png"></a></p>';
  const successResponse = {
    link: {
      markdown: '[GitLab](https://gitlab.com)',
    },
  };
  const parseHTML = (html) => new DOMParser().parseFromString(html, 'text/html');
  let mock;
  let renderMarkdown;
  let renderedMarkdown;

  beforeEach(() => {
    const formData = new FormData();
    formData.append('file', file);

    renderedMarkdown = parseHTML(renderedAttachmentLinkFixture);

    mock = new MockAdapter(axios);
    mock.onPost(uploadsPath, formData).reply(HTTP_STATUS_OK, successResponse);
    renderMarkdown = jest.fn().mockResolvedValue({ body: renderedAttachmentLinkFixture });
  });

  afterEach(() => {
    mock.restore();
  });

  it('returns src and canonicalSrc of uploaded file', async () => {
    const response = await uploadFile({ uploadsPath, renderMarkdown, file });

    expect(renderMarkdown).toHaveBeenCalledWith(successResponse.link.markdown);
    expect(response).toEqual({
      src: renderedMarkdown.querySelector('a').getAttribute('href'),
      canonicalSrc: renderedMarkdown.querySelector('a').dataset.canonicalSrc,
    });
  });
});
