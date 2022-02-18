import { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import { TEST_HOST, FIXTURES_PATH } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

const markdownPreviewPath = `${TEST_HOST}/preview`;
const markdownDocsPath = `${TEST_HOST}/docs`;
const textareaValue = 'testing\n123';
const uploadsPath = 'test/uploads';

function assertMarkdownTabs(isWrite, writeLink, previewLink, wrapper) {
  expect(writeLink.element.children[0].classList.contains('active')).toBe(isWrite);
  expect(previewLink.element.children[0].classList.contains('active')).toBe(!isWrite);
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
    axiosMock.restore();
  });

  function createSubject(lines = []) {
    // We actually mount a wrapper component so that we can force Vue to rerender classes in order to test a regression
    // caused by mixing Vanilla JS and Vue.
    subject = mountExtended(
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
          lines,
        },
        provide: {
          glFeatures: {
            contactsAutocomplete: true,
          },
        },
      },
    );
  }

  const getPreviewLink = () => subject.findByTestId('preview-tab');
  const getWriteLink = () => subject.findByTestId('write-tab');
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

      it('sets preview link as active', async () => {
        previewLink = getPreviewLink();
        previewLink.vm.$emit('click', { target: {} });

        await nextTick();
        expect(previewLink.element.children[0].classList.contains('active')).toBe(true);
      });

      it('shows preview loading text', async () => {
        previewLink = getPreviewLink();
        previewLink.vm.$emit('click', { target: {} });

        await nextTick();
        expect(subject.find('.md-preview-holder').element.textContent.trim()).toContain('Loading…');
      });

      it('renders markdown preview and GFM', async () => {
        const renderGFMSpy = jest.spyOn($.fn, 'renderGFM');

        previewLink = getPreviewLink();

        previewLink.vm.$emit('click', { target: {} });

        await axios.waitFor(markdownPreviewPath);
        expect(subject.find('.md-preview-holder').element.innerHTML).toContain(previewHTML);
        expect(renderGFMSpy).toHaveBeenCalled();
      });

      it('calls video.pause() on comment input when isSubmitting is changed to true', async () => {
        previewLink = getPreviewLink();
        previewLink.vm.$emit('click', { target: {} });

        await axios.waitFor(markdownPreviewPath);
        const video = getVideo();
        const callPause = jest.spyOn(video.element, 'pause').mockImplementation(() => true);

        subject.setProps({ isSubmitting: true });

        await nextTick();
        expect(callPause).toHaveBeenCalled();
      });

      it('clicking already active write or preview link does nothing', async () => {
        writeLink = getWriteLink();
        previewLink = getPreviewLink();

        writeLink.vm.$emit('click', { target: {} });
        await nextTick();

        assertMarkdownTabs(true, writeLink, previewLink, subject);
        writeLink.vm.$emit('click', { target: {} });
        await nextTick();

        assertMarkdownTabs(true, writeLink, previewLink, subject);
        previewLink.vm.$emit('click', { target: {} });
        await nextTick();

        assertMarkdownTabs(false, writeLink, previewLink, subject);
        previewLink.vm.$emit('click', { target: {} });
        await nextTick();

        assertMarkdownTabs(false, writeLink, previewLink, subject);
      });
    });

    describe('markdown buttons', () => {
      it('converts single words', async () => {
        const textarea = subject.find('textarea').element;
        textarea.setSelectionRange(0, 7);
        const markdownButton = getMarkdownButton();
        markdownButton.trigger('click');

        await nextTick();
        expect(textarea.value).toContain('**testing**');
      });

      it('converts a line', async () => {
        const textarea = subject.find('textarea').element;
        textarea.setSelectionRange(0, 0);
        const markdownButton = getAllMarkdownButtons().wrappers[5];
        markdownButton.trigger('click');

        await nextTick();
        expect(textarea.value).toContain('- testing');
      });

      it('converts multiple lines', async () => {
        const textarea = subject.find('textarea').element;
        textarea.setSelectionRange(0, 50);
        const markdownButton = getAllMarkdownButtons().wrappers[5];
        markdownButton.trigger('click');

        await nextTick();
        expect(textarea.value).toContain('- testing\n- 123');
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

        await nextTick();
      });

      it('should have rerendered classes and kept gfm-form', () => {
        expect(subject.classes()).toEqual(expect.arrayContaining(['gfm-form', 'foo']));
      });

      it('should trigger dropzone when attach button is clicked', () => {
        expect(dropzoneSpy).not.toHaveBeenCalled();

        clickAttachButton();

        expect(dropzoneSpy).toHaveBeenCalled();
      });

      describe('mentioning all users', () => {
        const users = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map((i) => `user_${i}`);

        it('shows warning on mention of all users', async () => {
          axiosMock.onPost(markdownPreviewPath).reply(200, { references: { users } });

          subject.setProps({ textareaValue: 'hello @all' });

          await axios.waitFor(markdownPreviewPath).then(() => {
            expect(subject.text()).toContain(
              'You are about to add 11 people to the discussion. They will all receive a notification.',
            );
          });
        });

        it('removes warning when all mention is removed', async () => {
          axiosMock.onPost(markdownPreviewPath).reply(200, { references: { users } });

          subject.setProps({ textareaValue: 'hello @all' });

          await axios.waitFor(markdownPreviewPath);

          jest.spyOn(axios, 'post');

          subject.setProps({ textareaValue: 'hello @allan' });

          await nextTick();

          expect(axios.post).not.toHaveBeenCalled();
          expect(subject.text()).not.toContain(
            'You are about to add 11 people to the discussion. They will all receive a notification.',
          );
        });
      });
    });
  });

  describe('suggestions', () => {
    it('escapes new line characters', () => {
      createSubject([{ rich_text: 'hello world\\n' }]);

      expect(subject.find('[data-testid="markdownHeader"]').props('lineContent')).toBe(
        'hello world%br',
      );
    });
  });
});
