import $ from 'jquery';
import { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import { TEST_HOST, FIXTURES_PATH } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import MarkdownFieldHeader from '~/vue_shared/components/markdown/header.vue';
import MarkdownToolbar from '~/vue_shared/components/markdown/toolbar.vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

jest.mock('~/behaviors/markdown/render_gfm');

const markdownPreviewPath = `${TEST_HOST}/preview`;
const markdownDocsPath = `${TEST_HOST}/docs`;
const textareaValue = 'testing\n123';
const uploadsPath = 'test/uploads';
const restrictedToolBarItems = ['quote'];

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

  function createSubject({ lines = [], enablePreview = true, showContentEditorSwitcher } = {}) {
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
          enablePreview,
          restrictedToolBarItems,
          showContentEditorSwitcher,
          supportsQuickActions: true,
        },
        mocks: {
          $apollo: {
            queries: {
              currentUser: {
                loading: false,
              },
            },
          },
        },
      },
    );
  }

  function createWrapper({ autocompleteDataSources = {} } = {}) {
    subject = shallowMountExtended(MarkdownField, {
      propsData: {
        markdownDocsPath,
        markdownPreviewPath,
        isSubmitting: false,
        textareaValue,
        lines: [],
        enablePreview: true,
        restrictedToolBarItems,
        showContentEditorSwitcher: false,
        autocompleteDataSources,
      },
    });
  }

  const getPreviewToggle = () => subject.findByTestId('preview-toggle');
  const getMarkdownButton = () => subject.find('.js-md');
  const getListBulletedButton = () => subject.findAll('.js-md[title="Add a bullet list"]');
  const getVideo = () => subject.find('video');
  const getAttachButton = () => subject.findByTestId('button-attach-file');
  const clickAttachButton = () => getAttachButton().trigger('click');
  const findDropzone = () => subject.find('.div-dropzone');
  const findMarkdownHeader = () => subject.findComponent(MarkdownFieldHeader);
  const findMarkdownToolbar = () => subject.findComponent(MarkdownToolbar);
  const findGlForm = () => $(subject.vm.$refs['gl-form']).data('glForm');

  describe('mounted', () => {
    const previewHTML = `
    <p>markdown preview</p>
    <video src="${FIXTURES_PATH}/static/mock-video.mp4"></video>
  `;
    let previewToggle;
    let dropzoneSpy;

    beforeEach(() => {
      dropzoneSpy = jest.fn();
      createSubject();
      findDropzone().element.addEventListener('click', dropzoneSpy);
    });

    describe('GlForm', () => {
      beforeEach(() => {
        createWrapper({ autocompleteDataSources: { commands: '/foobar/-/autocomplete_sources' } });
      });

      it('initializes GlForm with autocomplete data sources', () => {
        expect(findGlForm().autoComplete.dataSources).toMatchObject({
          commands: '/foobar/-/autocomplete_sources',
        });
      });
    });

    it('renders textarea inside backdrop', () => {
      expect(subject.find('.zen-backdrop textarea').element).not.toBeNull();
    });

    it('renders referenced commands on markdown preview', async () => {
      axiosMock
        .onPost(markdownPreviewPath)
        .reply(HTTP_STATUS_OK, { references: { users: [], commands: 'test command' } });

      previewToggle = getPreviewToggle();
      previewToggle.vm.$emit('click', true);

      await axios.waitFor(markdownPreviewPath);
      const referencedCommands = subject.find('[data-testid="referenced-commands"]');

      expect(referencedCommands.exists()).toBe(true);
      expect(referencedCommands.text()).toContain('test command');
    });

    it('clears referenced commands if there are no referenced commands on markdown preview', async () => {
      axiosMock.onPost(markdownPreviewPath).reply(HTTP_STATUS_OK, { references: { users: [] } });

      previewToggle = getPreviewToggle();
      previewToggle.vm.$emit('click', true);

      await axios.waitFor(markdownPreviewPath);
      const referencedCommands = subject.find('[data-testid="referenced-commands"]');

      expect(referencedCommands.exists()).toBe(false);
    });

    describe('markdown preview', () => {
      describe.each`
        data
        ${{ body: previewHTML }}
        ${{ html: previewHTML }}
      `('when api returns $data', ({ data }) => {
        beforeEach(() => {
          axiosMock.onPost(markdownPreviewPath).reply(HTTP_STATUS_OK, data);
        });

        it('sets preview toggle as active', async () => {
          previewToggle = getPreviewToggle();

          expect(previewToggle.text()).toBe('Preview');

          previewToggle.vm.$emit('click', true);

          await nextTick();
          expect(previewToggle.text()).toBe('Continue editing');
        });

        it('shows preview loading text', async () => {
          previewToggle = getPreviewToggle();
          previewToggle.vm.$emit('click', true);

          await nextTick();
          expect(subject.find('.md-preview-holder').element.textContent.trim()).toContain(
            'Loading…',
          );
        });

        it('renders markdown preview and GFM', async () => {
          previewToggle = getPreviewToggle();

          previewToggle.vm.$emit('click', true);

          await axios.waitFor(markdownPreviewPath);
          expect(subject.find('.md-preview-holder').element.innerHTML).toContain(previewHTML);
          expect(renderGFM).toHaveBeenCalled();
        });

        it('calls video.pause() on comment input when isSubmitting is changed to true', async () => {
          previewToggle = getPreviewToggle();
          previewToggle.vm.$emit('click', true);

          await axios.waitFor(markdownPreviewPath);
          const video = getVideo();
          const callPause = jest.spyOn(video.element, 'pause').mockImplementation(() => true);

          subject.setProps({ isSubmitting: true });

          await nextTick();
          expect(callPause).toHaveBeenCalled();
        });

        it('switches between preview/write on toggle', async () => {
          previewToggle = getPreviewToggle();

          previewToggle.vm.$emit('click', true);
          await nextTick();
          expect(subject.find('.md-preview-holder').element.style.display).toBe(''); // visible

          previewToggle.vm.$emit('click', false);
          await nextTick();
          expect(subject.find('.md-preview-holder').element.style.display).toBe('none');
        });

        it('passes correct props to MarkdownHeader and MarkdownToolbar', () => {
          expect(findMarkdownToolbar().props()).toEqual({
            canAttachFile: true,
            markdownDocsPath,
            showCommentToolBar: true,
            showContentEditorSwitcher: false,
          });

          expect(findMarkdownHeader().props()).toMatchObject({
            supportsQuickActions: true,
          });
        });
      });
    });

    describe('markdown buttons', () => {
      beforeEach(() => {
        // needed for the underlying insertText to work
        document.execCommand = jest.fn(() => false);
      });

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
        const markdownButton = getListBulletedButton();
        markdownButton.trigger('click');

        await nextTick();
        expect(textarea.value).toContain('- testing');
      });

      it('converts multiple lines', async () => {
        const textarea = subject.find('textarea').element;
        textarea.setSelectionRange(0, 50);
        const markdownButton = getListBulletedButton();
        markdownButton.trigger('click');

        await nextTick();
        expect(textarea.value).toContain('- testing\n- 123');
      });
    });

    it('should trigger dropzone when attach button is clicked', () => {
      expect(dropzoneSpy).not.toHaveBeenCalled();

      getAttachButton().trigger('click');
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
          axiosMock.onPost(markdownPreviewPath).reply(HTTP_STATUS_OK, { references: { users } });

          subject.setProps({ textareaValue: 'hello @all' });

          await axios.waitFor(markdownPreviewPath).then(() => {
            expect(subject.text()).toContain(
              'You are about to add 11 people to the discussion. They will all receive a notification.',
            );
          });
        });

        it('removes warning when all mention is removed', async () => {
          axiosMock.onPost(markdownPreviewPath).reply(HTTP_STATUS_OK, { references: { users } });

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

        it('removes warning when all mention is removed while endpoint is loading', async () => {
          axiosMock.onPost(markdownPreviewPath).reply(HTTP_STATUS_OK, { references: { users } });
          jest.spyOn(axios, 'post');

          subject.setProps({ textareaValue: 'hello @all' });

          await nextTick();

          subject.setProps({ textareaValue: 'hello @allan' });

          await axios.waitFor(markdownPreviewPath);

          expect(axios.post).toHaveBeenCalled();
          expect(subject.text()).not.toContain(
            'You are about to add 11 people to the discussion. They will all receive a notification.',
          );
        });
      });
    });
  });

  describe('suggestions', () => {
    it('escapes new line characters', () => {
      createSubject({ lines: [{ rich_text: 'hello world\\n' }] });

      expect(findMarkdownHeader().props('lineContent')).toBe('hello world%br');
    });
  });

  it('allows enabling and disabling Markdown Preview', () => {
    createSubject({ enablePreview: false });

    expect(subject.findComponent(MarkdownFieldHeader).props('enablePreview')).toBe(false);

    subject.destroy();
    createSubject({ enablePreview: true });

    expect(subject.findComponent(MarkdownFieldHeader).props('enablePreview')).toBe(true);
  });

  it('passess restricted tool bar items', () => {
    createSubject();

    expect(subject.findComponent(MarkdownFieldHeader).props('restrictedToolBarItems')).toBe(
      restrictedToolBarItems,
    );
  });

  describe('showContentEditorSwitcher', () => {
    it('defaults to false', () => {
      createSubject();

      expect(findMarkdownToolbar().props('showContentEditorSwitcher')).toBe(false);
    });

    it('passes showContentEditorSwitcher', () => {
      createSubject({ showContentEditorSwitcher: true });

      expect(findMarkdownToolbar().props('showContentEditorSwitcher')).toBe(true);
    });
  });
});
