import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MarkdownContent from '~/vue_shared/components/markdown/markdown_content.vue';
import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';

const MARKDOWN_PATH = '/api/:version/markdown';

// Original markdown
const MARKDOWN = 'Checkout [GitLab](http://gitlab.com) "><script>alert(1)</script>';
// HTML returned from /api/v4/markdown
const RENDERED_MARKDOWN =
  '\u003cp data-sourcepos="1:1-1:79" dir="auto"\u003eCheckout \u003ca href="http://gitlab.com"\u003eGitLab\u003c/a\u003e Hello! Welcome "\u0026gt;\u003c/p\u003e';
// HTML with v-safe-html
const HTML_SAFE_RENDERED_MARKDOWN =
  '\u003cp dir="auto" data-sourcepos="1:1-1:79"\u003eCheckout \u003ca href="http://gitlab.com"\u003eGitLab\u003c/a\u003e Hello! Welcome "\u0026gt;\u003c/p\u003e';

describe('markdown_content.vue', () => {
  let wrapper;
  let mock;

  const createWrapper = () => {
    wrapper = shallowMountExtended(MarkdownContent, {
      propsData: {
        value: MARKDOWN,
      },
    });
  };

  const url = buildApiUrl(MARKDOWN_PATH);

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findMarkdown = () => wrapper.findByTestId('markdown');

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('when loading', () => {
    it('shows the loading icon', () => {
      createWrapper();

      expect(findSkeletonLoader().exists()).toBe(true);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      mock
        .onPost(url, {
          text: MARKDOWN,
          gfm: true,
        })
        .replyOnce(HTTP_STATUS_OK, { html: RENDERED_MARKDOWN });
    });

    it('shows markdown', async () => {
      createWrapper();

      await axios.waitForAll();
      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findMarkdown().element.innerHTML).toBe(HTML_SAFE_RENDERED_MARKDOWN);
    });
  });

  describe('on error', () => {
    beforeEach(() => {
      mock
        .onPost(url, {
          text: MARKDOWN,
          gfm: true,
        })
        .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, new Error('error'));
    });

    it('shows the error message', async () => {
      createWrapper();

      await axios.waitForAll();
      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findAlert().props()).toMatchObject({
        variant: 'danger',
        dismissible: false,
      });
      expect(findAlert().text()).toBe('Failed to format markdown.');
    });
  });
});
