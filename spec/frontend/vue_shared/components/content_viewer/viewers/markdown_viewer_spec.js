import { GlSkeletonLoader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import MarkdownViewer from '~/vue_shared/components/content_viewer/viewers/markdown_viewer.vue';

jest.mock('~/behaviors/markdown/render_gfm');

describe('MarkdownViewer', () => {
  let wrapper;
  let mock;

  const createComponent = (props) => {
    wrapper = mount(MarkdownViewer, {
      propsData: {
        ...props,
        path: 'test.md',
        content: '*  Test',
        projectPath: 'testproject',
        type: 'markdown',
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    jest.spyOn(axios, 'post');
  });

  afterEach(() => {
    mock.restore();
  });

  describe('success', () => {
    beforeEach(() => {
      mock
        .onPost(`${gon.relative_url_root}/testproject/-/preview_markdown`)
        .replyOnce(HTTP_STATUS_OK, {
          body: '<b>testing</b> {{gl_md_img_1}}',
        });
    });

    it('renders a skeleton loader while the markdown is loading', () => {
      createComponent();

      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });

    it('renders markdown preview preview renders and loads rendered markdown from server', () => {
      createComponent();

      return waitForPromises().then(() => {
        expect(wrapper.find('.md-previewer').text()).toContain('testing');
      });
    });

    it('receives the filePath and commitSha as a parameters and passes them on to the server', () => {
      createComponent({ filePath: 'foo/test.md', commitSha: 'abcdef' });

      expect(axios.post).toHaveBeenCalledWith(
        `${gon.relative_url_root}/testproject/-/preview_markdown`,
        { path: 'foo/test.md', text: '*  Test', ref: 'abcdef' },
        expect.any(Object),
      );
    });

    it.each`
      imgSrc                               | imgAlt
      ${'data:image/jpeg;base64,AAAAAA+/'} | ${'my image title'}
      ${'data:image/jpeg;base64,AAAAAA+/'} | ${'"somebody\'s image" &'}
      ${'hack" onclick=alert(0)'}          | ${'hack" onclick=alert(0)'}
      ${'hack\\" onclick=alert(0)'}        | ${'hack\\" onclick=alert(0)'}
      ${"hack' onclick=alert(0)"}          | ${"hack' onclick=alert(0)"}
      ${"hack'><script>alert(0)</script>"} | ${"hack'><script>alert(0)</script>"}
    `(
      'transforms template tags with base64 encoded images available locally',
      ({ imgSrc, imgAlt }) => {
        createComponent({
          images: {
            '{{gl_md_img_1}}': {
              src: imgSrc,
              alt: imgAlt,
              title: imgAlt,
            },
          },
        });

        return waitForPromises().then(() => {
          const img = wrapper.find('.md-previewer img').element;

          // if the values are the same as the input, it means
          // they were escaped correctly
          expect(img).toHaveAttr('src', imgSrc);
          expect(img).toHaveAttr('alt', imgAlt);
          expect(img).toHaveAttr('title', imgAlt);
        });
      },
    );
  });

  describe('error', () => {
    beforeEach(() => {
      mock
        .onPost(`${gon.relative_url_root}/testproject/preview_markdown`)
        .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {
          body: 'Internal Server Error',
        });
    });
    it('renders an error message if loading the markdown preview fails', () => {
      createComponent();

      return waitForPromises().then(() => {
        expect(wrapper.find('.md-previewer').text()).toContain('error');
      });
    });
  });
});
