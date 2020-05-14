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
        body: '<b>testing</b>',
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

    it('receives the filePath as a parameter and passes it on to the server', () => {
      createComponent({ filePath: 'foo/test.md' });

      expect(axios.post).toHaveBeenCalledWith(
        `${gon.relative_url_root}/testproject/preview_markdown`,
        { path: 'foo/test.md', text: '*  Test' },
        expect.any(Object),
      );
    });
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
