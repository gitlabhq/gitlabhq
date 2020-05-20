import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import MarkdownViewer from '~/vue_shared/components/content_viewer/viewers/markdown_viewer.vue';

describe('MarkdownViewer', () => {
  let wrapper;
  let mock;

  const createComponent = props => {
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
    jest.spyOn($.fn, 'renderGFM');
  });

  afterEach(() => {
    mock.restore();
  });

  describe('success', () => {
    beforeEach(() => {
      mock.onPost(`${gon.relative_url_root}/testproject/preview_markdown`).replyOnce(200, {
        body: '<b>testing</b> {{gl_md_img_1}}',
      });
    });

    it('renders an animation container while the markdown is loading', () => {
      createComponent();

      expect(wrapper.find('.animation-container')).toExist();
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
        `${gon.relative_url_root}/testproject/preview_markdown`,
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
      mock.onPost(`${gon.relative_url_root}/testproject/preview_markdown`).replyOnce(500, {
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
