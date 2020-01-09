import { mount } from '@vue/test-utils';
import fieldComponent from '~/vue_shared/components/markdown/field.vue';
import { TEST_HOST, FIXTURES_PATH } from 'spec/test_constants';
import AxiosMockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';

const markdownPreviewPath = `${TEST_HOST}/preview`;
const markdownDocsPath = `${TEST_HOST}/docs`;

function assertMarkdownTabs(isWrite, writeLink, previewLink, wrapper) {
  expect(writeLink.element.parentNode.classList.contains('active')).toEqual(isWrite);
  expect(previewLink.element.parentNode.classList.contains('active')).toEqual(!isWrite);
  expect(wrapper.find('.md-preview-holder').element.style.display).toEqual(isWrite ? 'none' : '');
}

function createComponent() {
  const wrapper = mount(fieldComponent, {
    propsData: {
      markdownDocsPath,
      markdownPreviewPath,
      isSubmitting: false,
    },
    slots: {
      textarea: '<textarea>testing\n123</textarea>',
    },
    template: `
    <field-component
      markdown-preview-path="${markdownPreviewPath}"
      markdown-docs-path="${markdownDocsPath}"
      :isSubmitting="false"
    >
      <textarea
        slot="textarea"
        v-model="text">
        <slot>this is a test</slot>
      </textarea>
    </field-component>
    `,
    sync: false,
  });
  return wrapper;
}

const getPreviewLink = wrapper => wrapper.find('.nav-links .js-preview-link');
const getWriteLink = wrapper => wrapper.find('.nav-links .js-write-link');
const getMarkdownButton = wrapper => wrapper.find('.js-md');
const getAllMarkdownButtons = wrapper => wrapper.findAll('.js-md');
const getVideo = wrapper => wrapper.find('video');

describe('Markdown field component', () => {
  let axiosMock;

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('mounted', () => {
    let wrapper;
    const previewHTML = `
    <p>markdown preview</p>
    <video src="${FIXTURES_PATH}/static/mock-video.mp4" muted="muted"></video>
  `;
    let previewLink;
    let writeLink;

    it('renders textarea inside backdrop', () => {
      wrapper = createComponent();
      expect(wrapper.find('.zen-backdrop textarea').element).not.toBeNull();
    });

    describe('markdown preview', () => {
      beforeEach(() => {
        axiosMock.onPost(markdownPreviewPath).reply(200, { body: previewHTML });
      });

      it('sets preview link as active', () => {
        wrapper = createComponent();
        previewLink = getPreviewLink(wrapper);
        previewLink.trigger('click');

        return wrapper.vm.$nextTick().then(() => {
          expect(previewLink.element.parentNode.classList.contains('active')).toBeTruthy();
        });
      });

      it('shows preview loading text', () => {
        wrapper = createComponent();
        previewLink = getPreviewLink(wrapper);
        previewLink.trigger('click');

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find('.md-preview-holder').element.textContent.trim()).toContain(
            'Loading…',
          );
        });
      });

      it('renders markdown preview', () => {
        wrapper = createComponent();
        previewLink = getPreviewLink(wrapper);
        previewLink.trigger('click');

        setTimeout(() => {
          expect(wrapper.find('.md-preview-holder').element.innerHTML).toContain(previewHTML);
        });
      });

      it('renders GFM with jQuery', () => {
        wrapper = createComponent();
        previewLink = getPreviewLink(wrapper);
        jest.spyOn($.fn, 'renderGFM');

        previewLink.trigger('click');

        return axios.waitFor(markdownPreviewPath).then(() => {
          expect(wrapper.find('.md-preview-holder').element.innerHTML).toContain(previewHTML);
        });
      });

      it('calls video.pause() on comment input when isSubmitting is changed to true', () => {
        wrapper = createComponent();
        previewLink = getPreviewLink(wrapper);
        previewLink.trigger('click');

        let callPause;

        return axios
          .waitFor(markdownPreviewPath)
          .then(() => {
            const video = getVideo(wrapper);
            callPause = jest.spyOn(video.element, 'pause').mockImplementation(() => true);

            wrapper.setProps({
              isSubmitting: true,
              markdownPreviewPath,
              markdownDocsPath,
            });

            return wrapper.vm.$nextTick();
          })
          .then(() => {
            expect(callPause).toHaveBeenCalled();
          });
      });

      it('clicking already active write or preview link does nothing', () => {
        wrapper = createComponent();
        writeLink = getWriteLink(wrapper);
        previewLink = getPreviewLink(wrapper);

        writeLink.trigger('click');
        return wrapper.vm
          .$nextTick()
          .then(() => assertMarkdownTabs(true, writeLink, previewLink, wrapper))
          .then(() => writeLink.trigger('click'))
          .then(() => wrapper.vm.$nextTick())
          .then(() => assertMarkdownTabs(true, writeLink, previewLink, wrapper))
          .then(() => previewLink.trigger('click'))
          .then(() => wrapper.vm.$nextTick())
          .then(() => assertMarkdownTabs(false, writeLink, previewLink, wrapper))
          .then(() => previewLink.trigger('click'))
          .then(() => wrapper.vm.$nextTick())
          .then(() => assertMarkdownTabs(false, writeLink, previewLink, wrapper));
      });
    });

    describe('markdown buttons', () => {
      it('converts single words', () => {
        wrapper = createComponent();
        const textarea = wrapper.find('textarea').element;
        textarea.setSelectionRange(0, 7);
        const markdownButton = getMarkdownButton(wrapper);
        markdownButton.trigger('click');

        wrapper.vm.$nextTick(() => {
          expect(textarea.value).toContain('**testing**');
        });
      });

      it('converts a line', () => {
        wrapper = createComponent();
        const textarea = wrapper.find('textarea').element;
        textarea.setSelectionRange(0, 0);
        const markdownButton = getAllMarkdownButtons(wrapper).wrappers[5];
        markdownButton.trigger('click');

        wrapper.vm.$nextTick(() => {
          expect(textarea.value).toContain('*  testing');
        });
      });

      it('converts multiple lines', () => {
        wrapper = createComponent();
        const textarea = wrapper.find('textarea').element;
        textarea.setSelectionRange(0, 50);
        const markdownButton = getAllMarkdownButtons(wrapper).wrappers[5];
        markdownButton.trigger('click');

        wrapper.vm.$nextTick(() => {
          expect(textarea.value).toContain('* testing\n* 123');
        });
      });
    });
  });
});
