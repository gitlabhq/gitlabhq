import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import mountComponent from 'helpers/vue_mount_component_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { GREEN_BOX_IMAGE_URL } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import contentViewer from '~/vue_shared/components/content_viewer/content_viewer.vue';
import '~/behaviors/markdown/render_gfm';

describe('ContentViewer', () => {
  let vm;
  let mock;

  function createComponent(props) {
    const ContentViewer = Vue.extend(contentViewer);
    vm = mountComponent(ContentViewer, props);
  }

  afterEach(() => {
    vm.$destroy();
    if (mock) mock.restore();
  });

  it('markdown preview renders + loads rendered markdown from server', done => {
    mock = new MockAdapter(axios);
    mock.onPost(`${gon.relative_url_root}/testproject/preview_markdown`).replyOnce(200, {
      body: '<b>testing</b>',
    });

    createComponent({
      path: 'test.md',
      content: '*  Test',
      projectPath: 'testproject',
      type: 'markdown',
    });

    waitForPromises()
      .then(() => {
        expect(vm.$el.querySelector('.md-previewer').textContent).toContain('testing');
      })
      .then(done)
      .catch(done.fail);
  });

  it('renders image preview', done => {
    createComponent({
      path: GREEN_BOX_IMAGE_URL,
      fileSize: 1024,
      type: 'image',
    });

    vm.$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('img').getAttribute('src')).toBe(GREEN_BOX_IMAGE_URL);
      })
      .then(done)
      .catch(done.fail);
  });

  it('renders fallback download control', done => {
    createComponent({
      path: 'somepath/test.abc',
      fileSize: 1024,
    });

    vm.$nextTick()
      .then(() => {
        expect(
          vm.$el
            .querySelector('.file-info')
            .textContent.trim()
            .replace(/\s+/, ' '),
        ).toEqual('test.abc (1.00 KiB)');

        expect(vm.$el.querySelector('.btn.btn-default').textContent.trim()).toEqual('Download');
      })
      .then(done)
      .catch(done.fail);
  });

  it('renders fallback download control for file with a data URL path properly', done => {
    createComponent({
      path: 'data:application/octet-stream;base64,U0VMRUNUICfEhHNnc2cnIGZyb20gVGFibGVuYW1lOwoK',
      filePath: 'somepath/test.abc',
    });

    vm.$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.file-info').textContent.trim()).toEqual('test.abc');
        expect(vm.$el.querySelector('.btn.btn-default')).toHaveAttr('download', 'test.abc');
        expect(vm.$el.querySelector('.btn.btn-default').textContent.trim()).toEqual('Download');
      })
      .then(done)
      .catch(done.fail);
  });

  it('markdown preview receives the file path as a parameter', done => {
    mock = new MockAdapter(axios);
    jest.spyOn(axios, 'post');
    mock.onPost(`${gon.relative_url_root}/testproject/preview_markdown`).reply(200, {
      body: '<b>testing</b>',
    });

    createComponent({
      path: 'test.md',
      content: '*  Test',
      projectPath: 'testproject',
      type: 'markdown',
      filePath: 'foo/test.md',
    });

    vm.$nextTick()
      .then(() => {
        expect(axios.post).toHaveBeenCalledWith(
          `${gon.relative_url_root}/testproject/preview_markdown`,
          { path: 'foo/test.md', text: '*  Test' },
          expect.any(Object),
        );
      })
      .then(done)
      .catch(done.fail);
  });
});
