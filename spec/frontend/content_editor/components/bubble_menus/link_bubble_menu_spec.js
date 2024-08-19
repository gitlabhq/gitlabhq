import { GlLink, GlForm } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import LinkBubbleMenu from '~/content_editor/components/bubble_menus/link_bubble_menu.vue';
import EditorStateObserver from '~/content_editor/components/editor_state_observer.vue';
import eventHubFactory from '~/helpers/event_hub_factory';
import BubbleMenu from '~/content_editor/components/bubble_menus/bubble_menu.vue';
import { stubComponent } from 'helpers/stub_component';
import Link from '~/content_editor/extensions/link';
import { createTestEditor, emitEditorEvent, createTransactionWithMeta } from '../../test_utils';

const createFakeEvent = () => ({ preventDefault: jest.fn(), stopPropagation: jest.fn() });

describe('content_editor/components/bubble_menus/link_bubble_menu', () => {
  let wrapper;
  let tiptapEditor;
  let contentEditor;
  let eventHub;

  const buildEditor = () => {
    tiptapEditor = createTestEditor({ extensions: [Link] });
    contentEditor = { resolveUrl: jest.fn() };
    eventHub = eventHubFactory();
  };

  const buildWrapper = () => {
    wrapper = mountExtended(LinkBubbleMenu, {
      provide: {
        tiptapEditor,
        contentEditor,
        eventHub,
      },
      stubs: {
        BubbleMenu: stubComponent(BubbleMenu),
      },
    });
  };

  const showMenu = () => {
    wrapper.findComponent(BubbleMenu).vm.$emit('show');
    return nextTick();
  };

  const buildWrapperAndDisplayMenu = () => {
    buildWrapper();

    return showMenu();
  };

  const findBubbleMenu = () => wrapper.findComponent(BubbleMenu);
  const findLink = () => wrapper.findComponent(GlLink);
  const findEditorStateObserver = () => wrapper.findComponent(EditorStateObserver);
  const findEditLinkButton = () => wrapper.findByTestId('edit-link');

  const expectLinkButtonsToExist = (exist = true) => {
    expect(wrapper.findComponent(GlLink).exists()).toBe(exist);
    expect(wrapper.findByTestId('copy-link-url').exists()).toBe(exist);
    expect(wrapper.findByTestId('edit-link').exists()).toBe(exist);
    expect(wrapper.findByTestId('remove-link').exists()).toBe(exist);
  };

  beforeEach(() => {
    buildEditor();

    tiptapEditor
      .chain()
      .setContent(
        'Download <a href="/path/to/project/-/wikis/uploads/my_file.pdf" data-canonical-src="uploads/my_file.pdf">PDF File</a>',
      )
      .setTextSelection(14) // put cursor in the middle of the link
      .run();
  });

  it('renders bubble menu component', async () => {
    await buildWrapperAndDisplayMenu();

    expect(findBubbleMenu().classes()).toEqual(['gl-rounded-base', 'gl-bg-white', 'gl-shadow']);
  });

  it('shows a clickable link to the URL in the link node', async () => {
    await buildWrapperAndDisplayMenu();

    expect(findLink().attributes()).toEqual(
      expect.objectContaining({
        href: '/path/to/project/-/wikis/uploads/my_file.pdf',
        'aria-label': 'uploads/my_file.pdf',
        target: '_blank',
      }),
    );
    expect(findLink().text()).toBe('uploads/my_file.pdf');
  });

  it('shows a loading percentage for a file being uploaded', async () => {
    const setUploadProgress = async (progress) => {
      const transaction = createTransactionWithMeta('uploadProgress', {
        filename: 'my_file.pdf',
        progress,
      });
      await emitEditorEvent({ event: 'transaction', tiptapEditor, params: { transaction } });
    };

    tiptapEditor
      .chain()
      .extendMarkRange('link')
      .updateAttributes('link', { uploading: 'my_file.pdf' })
      .run();

    await buildWrapperAndDisplayMenu();

    expect(findLink().exists()).toBe(false);
    expect(wrapper.text()).toContain('Uploading: 0%');

    await setUploadProgress(0.4);
    expect(wrapper.text()).toContain('Uploading: 40%');

    await setUploadProgress(0.7);
    expect(wrapper.text()).toContain('Uploading: 70%');

    await setUploadProgress(1);
    expect(wrapper.text()).toContain('Uploading: 100%');
  });

  it('updates the bubble menu state when @selectionUpdate event is triggered', async () => {
    const linkUrl = 'https://gitlab.com';

    await buildWrapperAndDisplayMenu();

    expect(findLink().attributes()).toEqual(
      expect.objectContaining({
        href: '/path/to/project/-/wikis/uploads/my_file.pdf',
      }),
    );

    tiptapEditor
      .chain()
      .setContent(
        `Link to <a href="${linkUrl}" data-canonical-src="${linkUrl}" title="Click here to download">GitLab</a>`,
      )
      .setTextSelection(11)
      .run();

    findEditorStateObserver().vm.$emit('selectionUpdate');

    await nextTick();

    expect(findLink().attributes()).toEqual(
      expect.objectContaining({
        href: linkUrl,
      }),
    );
  });

  describe('when the selection changes within the same link', () => {
    it('does not update the bubble menu state', async () => {
      await buildWrapperAndDisplayMenu();

      await findEditLinkButton().trigger('click');

      expect(wrapper.findComponent(GlForm).exists()).toBe(true);

      tiptapEditor.commands.setTextSelection(13);

      findEditorStateObserver().vm.$emit('selectionUpdate');

      await nextTick();

      expect(wrapper.findComponent(GlForm).exists()).toBe(true);
    });
  });

  it('cleans bubble menu state when hidden event is triggered', async () => {
    await buildWrapperAndDisplayMenu();

    expect(findLink().attributes()).toEqual(
      expect.objectContaining({
        href: '/path/to/project/-/wikis/uploads/my_file.pdf',
      }),
    );

    findBubbleMenu().vm.$emit('hidden');

    await nextTick();

    expect(findLink().attributes()).toEqual(
      expect.objectContaining({
        href: '#',
      }),
    );
    expect(findLink().text()).toEqual('');
  });

  describe('copy button', () => {
    it('copies the canonical link to clipboard', async () => {
      await buildWrapperAndDisplayMenu();

      jest.spyOn(navigator.clipboard, 'writeText');

      await wrapper.findByTestId('copy-link-url').vm.$emit('click');

      expect(navigator.clipboard.writeText).toHaveBeenCalledWith('uploads/my_file.pdf');
    });
  });

  describe('remove link button', () => {
    it('removes the link', async () => {
      await buildWrapperAndDisplayMenu();
      await wrapper.findByTestId('remove-link').vm.$emit('click');

      expect(tiptapEditor.getHTML()).toBe('<p dir="auto">Download PDF File</p>');
    });
  });

  describe('edit button', () => {
    let linkHrefInput;

    beforeEach(async () => {
      await buildWrapperAndDisplayMenu();
      await wrapper.findByTestId('edit-link').vm.$emit('click');

      linkHrefInput = wrapper.findByTestId('link-href');
    });

    it('hides the link and copy/edit/remove link buttons', () => {
      expectLinkButtonsToExist(false);
    });

    it('shows a form to edit the link', () => {
      expect(wrapper.findComponent(GlForm).exists()).toBe(true);

      expect(linkHrefInput.element.value).toBe('uploads/my_file.pdf');
    });

    it('extends selection to select the entire link', () => {
      const { from, to } = tiptapEditor.state.selection;

      expect(from).toBe(10);
      expect(to).toBe(18);
    });

    describe('after making changes in the form and clicking apply', () => {
      beforeEach(async () => {
        linkHrefInput.setValue('https://google.com');

        contentEditor.resolveUrl.mockResolvedValue('https://google.com');

        await wrapper.findComponent(GlForm).vm.$emit('submit', createFakeEvent());
      });

      it('updates the link in the bubble menu', () => {
        const link = wrapper.findComponent(GlLink);
        expect(link.attributes()).toEqual(
          expect.objectContaining({
            href: 'https://google.com',
            'aria-label': 'https://google.com',
            target: '_blank',
          }),
        );
        expect(link.text()).toBe('https://google.com');
      });
    });

    describe('after making changes in the form and clicking cancel', () => {
      beforeEach(async () => {
        linkHrefInput.setValue('https://google.com');

        await wrapper.findByTestId('cancel-link').vm.$emit('click');
      });

      it('hides the form and shows the copy/edit/remove link buttons', () => {
        expectLinkButtonsToExist();
      });
    });
  });
});
