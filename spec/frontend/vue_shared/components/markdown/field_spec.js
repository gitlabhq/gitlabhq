import { mount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import { TEST_HOST, FIXTURES_PATH } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';

const markdownPreviewPath = `${TEST_HOST}/preview`;
const markdownDocsPath = `${TEST_HOST}/docs`;
const textareaValue = 'testing\n123';
const uploadsPath = 'test/uploads';

function assertMarkdownTabs(isWrite, writeLink, previewLink, wrapper) {
  expect(writeLink.element.parentNode.classList.contains('active')).toBe(isWrite);
  expect(previewLink.element.parentNode.classList.contains('active')).toBe(!isWrite);
  expect(wrapper.find('.md-preview-holder').element.style.display).toBe(isWrite ? 'none' : '');
}

describe('Markdown field component', () => {
  let axiosMock;
  let subject;

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    // window.uploads_path is needed for dropzone to initialize
    window.uploads_path = uploadsPath;
  });

  afterEach(() => {
    subject.destroy();
    subject = null;
    axiosMock.restore();
  });

  function createSubject() {
    // We actually mount a wrapper component so that we can force Vue to rerender classes in order to test a regression
    // caused by mixing Vanilla JS and Vue.
    subject = mount(
      {
        components: {
          MarkdownField,
        },
        props: {
          wrapperClasses: {
            type: String,
            required: false,
            default: '',
          },
        },
        template: `
<markdown-field :class="wrapperClasses" v-bind="$attrs">
  <template #textarea>
    <textarea class="js-gfm-input" :value="$attrs.textareaValue"></textarea>
  </template>
</markdown-field>`,
      },
      {
        propsData: {
          markdownDocsPath,
          markdownPreviewPath,
          isSubmitting: false,
          textareaValue,
        },
      },
    );
  }

  const getPreviewLink = () => subject.find('.nav-links .js-preview-link');
  const getWriteLink = () => subject.find('.nav-links .js-write-link');
  const getMarkdownButton = () => subject.find('.js-md');
  const getAllMarkdownButtons = () => subject.findAll('.js-md');
  const getVideo = () => subject.find('video');
  const getAttachButton = () => subject.find('.button-attach-file');
  const clickAttachButton = () => getAttachButton().trigger('click');
  const findDropzone = () => subject.find('.div-dropzone');

  describe('mounted', () => {
    const previewHTML = `
    <p>markdown preview</p>
    <video src="${FIXTURES_PATH}/static/mock-video.mp4" muted="muted"></video>
  `;
    let previewLink;
    let writeLink;
    let dropzoneSpy;

    beforeEach(() => {
      dropzoneSpy = jest.fn();
      createSubject();
      findDropzone().element.addEventListener('click', dropzoneSpy);
    });

    it('renders textarea inside backdrop', () => {
      expect(subject.find('.zen-backdrop textarea').element).not.toBeNull();
    });

    describe('markdown preview', () => {
      beforeEach(() => {
        axiosMock.onPost(markdownPreviewPath).reply(200, { body: previewHTML });
      });

      it('sets preview link as active', () => {
        previewLink = getPreviewLink();
        previewLink.trigger('click');

        return subject.vm.$nextTick().then(() => {
          expect(previewLink.element.parentNode.classList.contains('active')).toBeTruthy();
        });
      });

      it('shows preview loading text', () => {
        previewLink = getPreviewLink();
        previewLink.trigger('click');

        return subject.vm.$nextTick(() => {
          expect(subject.find('.md-preview-holder').element.textContent.trim()).toContain(
            'Loading…',
          );
        });
      });

      it('renders markdown preview and GFM', () => {
        const renderGFMSpy = jest.spyOn($.fn, 'renderGFM');

        previewLink = getPreviewLink();

        previewLink.trigger('click');

        return axios.waitFor(markdownPreviewPath).then(() => {
          expect(subject.find('.md-preview-holder').element.innerHTML).toContain(previewHTML);
          expect(renderGFMSpy).toHaveBeenCalled();
        });
      });

      it('calls video.pause() on comment input when isSubmitting is changed to true', () => {
        previewLink = getPreviewLink();
        previewLink.trigger('click');

        let callPause;

        return axios
          .waitFor(markdownPreviewPath)
          .then(() => {
            const video = getVideo();
            callPause = jest.spyOn(video.element, 'pause').mockImplementation(() => true);

            subject.setProps({ isSubmitting: true });

            return subject.vm.$nextTick();
          })
          .then(() => {
            expect(callPause).toHaveBeenCalled();
          });
      });

      it('clicking already active write or preview link does nothing', async () => {
        writeLink = getWriteLink();
        previewLink = getPreviewLink();

        writeLink.trigger('click');
        await subject.vm.$nextTick();

        assertMarkdownTabs(true, writeLink, previewLink, subject);
        writeLink.trigger('click');
        await subject.vm.$nextTick();

        assertMarkdownTabs(true, writeLink, previewLink, subject);
        previewLink.trigger('click');
        await subject.vm.$nextTick();

        assertMarkdownTabs(false, writeLink, previewLink, subject);
        previewLink.trigger('click');
        await subject.vm.$nextTick();

        assertMarkdownTabs(false, writeLink, previewLink, subject);
      });
    });

    describe('markdown buttons', () => {
      it('converts single words', () => {
        const textarea = subject.find('textarea').element;
        textarea.setSelectionRange(0, 7);
        const markdownButton = getMarkdownButton();
        markdownButton.trigger('click');

        return subject.vm.$nextTick(() => {
          expect(textarea.value).toContain('**testing**');
        });
      });

      it('converts a line', () => {
        const textarea = subject.find('textarea').element;
        textarea.setSelectionRange(0, 0);
        const markdownButton = getAllMarkdownButtons().wrappers[5];
        markdownButton.trigger('click');

        return subject.vm.$nextTick(() => {
          expect(textarea.value).toContain('- testing');
        });
      });

      it('converts multiple lines', () => {
        const textarea = subject.find('textarea').element;
        textarea.setSelectionRange(0, 50);
        const markdownButton = getAllMarkdownButtons().wrappers[5];
        markdownButton.trigger('click');

        return subject.vm.$nextTick(() => {
          expect(textarea.value).toContain('- testing\n- 123');
        });
      });
    });

    it('should render attach a file button', () => {
      expect(getAttachButton().text()).toBe('Attach a file');
    });

    it('should trigger dropzone when attach button is clicked', () => {
      expect(dropzoneSpy).not.toHaveBeenCalled();

      clickAttachButton();

      expect(dropzoneSpy).toHaveBeenCalled();
    });

    describe('when textarea has changed', () => {
      beforeEach(async () => {
        // Do something to trigger rerendering the class
        subject.setProps({ wrapperClasses: 'foo' });

        await subject.vm.$nextTick();
      });

      it('should have rerendered classes and kept gfm-form', () => {
        expect(subject.classes()).toEqual(expect.arrayContaining(['gfm-form', 'foo']));
      });

      it('should trigger dropzone when attach button is clicked', () => {
        expect(dropzoneSpy).not.toHaveBeenCalled();

        clickAttachButton();

        expect(dropzoneSpy).toHaveBeenCalled();
      });
    });
  });
});
