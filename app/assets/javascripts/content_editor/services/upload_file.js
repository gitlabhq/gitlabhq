import axios from '~/lib/utils/axios_utils';

const extractAttachmentLinkUrl = (html) => {
  const parser = new DOMParser();
  const { body } = parser.parseFromString(html, 'text/html');
  const link = body.querySelector('a');
  const src = link.getAttribute('href');
  const { canonicalSrc } = link.dataset;

  return { src, canonicalSrc };
};

/**
 * Uploads a file with a post request to the URL indicated
 * in the uploadsPath parameter. The expected response of the
 * uploads service is a JSON object that contains, at least, a
 * link property. The link property should contain markdown link
 * definition (i.e. [GitLab](https://gitlab.com)).
 *
 * This Markdown will be rendered to extract its canonical and full
 * URLs using GitLab Flavored Markdown renderer in the backend.
 *
 * @param {Object} params
 * @param {String} params.uploadsPath An absolute URL that points to a service
 * that allows sending a file for uploading via POST request.
 * @param {String} params.renderMarkdown A function that accepts a markdown string
 * and returns a rendered version in HTML format.
 * @param {File} params.file The file to upload
 *
 * @returns Returns an object with two properties:
 *
 * canonicalSrc: The URL as defined in the Markdown
 * src: The absolute URL that points to the resource in the server
 */
export const uploadFile = async ({ uploadsPath, renderMarkdown, file }) => {
  const formData = new FormData();
  formData.append('file', file, file.name);

  const { data } = await axios.post(uploadsPath, formData);
  const { markdown } = data.link;
  const rendered = await renderMarkdown(markdown);

  return extractAttachmentLinkUrl(rendered);
};
