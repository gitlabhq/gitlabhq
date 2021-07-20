import { GlDropdown, GlDropdownDivider, GlButton, GlFormInputGroup } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ToolbarLinkButton from '~/content_editor/components/toolbar_link_button.vue';
import { tiptapExtension as Link } from '~/content_editor/extensions/link';
import { hasSelection } from '~/content_editor/services/utils';
import { createTestEditor, mockChainedCommands } from '../test_utils';

jest.mock('~/content_editor/services/utils');

describe('content_editor/components/toolbar_link_button', () => {
  let wrapper;
  let editor;

  const buildWrapper = () => {
    wrapper = mountExtended(ToolbarLinkButton, {
      propsData: {
        tiptapEditor: editor,
      },
    });
  };
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownDivider = () => wrapper.findComponent(GlDropdownDivider);
  const findLinkURLInput = () => wrapper.findComponent(GlFormInputGroup).find('input[type="text"]');
  const findApplyLinkButton = () => wrapper.findComponent(GlButton);
  const findRemoveLinkButton = () => wrapper.findByText('Remove link');

  beforeEach(() => {
    editor = createTestEditor({
      extensions: [Link],
    });
  });

  afterEach(() => {
    editor.destroy();
    wrapper.destroy();
  });

  it('renders dropdown component', () => {
    buildWrapper();

    expect(findDropdown().html()).toMatchSnapshot();
  });

  describe('when there is an active link', () => {
    beforeEach(async () => {
      jest.spyOn(editor, 'isActive').mockReturnValueOnce(true);
      buildWrapper();
    });

    it('sets dropdown as active when link extension is active', () => {
      expect(findDropdown().props('toggleClass')).toEqual({ active: true });
    });

    it('displays a remove link dropdown option', () => {
      expect(findDropdownDivider().exists()).toBe(true);
      expect(wrapper.findByText('Remove link').exists()).toBe(true);
    });

    it('executes removeLink command when the remove link option is clicked', async () => {
      const commands = mockChainedCommands(editor, ['focus', 'unsetLink', 'run']);

      await findRemoveLinkButton().trigger('click');

      expect(commands.unsetLink).toHaveBeenCalled();
      expect(commands.focus).toHaveBeenCalled();
      expect(commands.run).toHaveBeenCalled();
    });

    it('updates the link with a new link when "Apply" button is clicked', async () => {
      const commands = mockChainedCommands(editor, ['focus', 'unsetLink', 'setLink', 'run']);

      await findLinkURLInput().setValue('https://example');
      await findApplyLinkButton().trigger('click');

      expect(commands.focus).toHaveBeenCalled();
      expect(commands.unsetLink).toHaveBeenCalled();
      expect(commands.setLink).toHaveBeenCalledWith({
        href: 'https://example',
        canonicalSrc: 'https://example',
      });
      expect(commands.run).toHaveBeenCalled();

      expect(wrapper.emitted().execute[0]).toEqual([{ contentType: 'link' }]);
    });

    describe('on selection update', () => {
      it('updates link input box with canonical-src if present', async () => {
        jest.spyOn(editor, 'getAttributes').mockReturnValueOnce({
          canonicalSrc: 'uploads/my-file.zip',
          href: '/username/my-project/uploads/abcdefgh133535/my-file.zip',
        });

        await editor.emit('selectionUpdate', { editor });

        expect(findLinkURLInput().element.value).toEqual('uploads/my-file.zip');
      });

      it('updates link input box with link href otherwise', async () => {
        jest.spyOn(editor, 'getAttributes').mockReturnValueOnce({
          href: 'https://gitlab.com',
        });

        await editor.emit('selectionUpdate', { editor });

        expect(findLinkURLInput().element.value).toEqual('https://gitlab.com');
      });
    });
  });

  describe('when there is not an active link', () => {
    beforeEach(() => {
      jest.spyOn(editor, 'isActive');
      editor.isActive.mockReturnValueOnce(false);
      buildWrapper();
    });

    it('does not set dropdown as active', () => {
      expect(findDropdown().props('toggleClass')).toEqual({ active: false });
    });

    it('does not display a remove link dropdown option', () => {
      expect(findDropdownDivider().exists()).toBe(false);
      expect(wrapper.findByText('Remove link').exists()).toBe(false);
    });

    it('sets the link to the value in the URL input when "Apply" button is clicked', async () => {
      const commands = mockChainedCommands(editor, ['focus', 'unsetLink', 'setLink', 'run']);

      await findLinkURLInput().setValue('https://example');
      await findApplyLinkButton().trigger('click');

      expect(commands.focus).toHaveBeenCalled();
      expect(commands.setLink).toHaveBeenCalledWith({
        href: 'https://example',
        canonicalSrc: 'https://example',
      });
      expect(commands.run).toHaveBeenCalled();

      expect(wrapper.emitted().execute[0]).toEqual([{ contentType: 'link' }]);
    });
  });

  describe('when the user displays the dropdown', () => {
    let commands;

    beforeEach(() => {
      commands = mockChainedCommands(editor, ['focus', 'extendMarkRange', 'run']);
    });

    describe('given the user has not selected text', () => {
      beforeEach(() => {
        hasSelection.mockReturnValueOnce(false);
      });

      it('the editor selection is extended to the current mark extent', () => {
        buildWrapper();

        findDropdown().vm.$emit('show');
        expect(commands.extendMarkRange).toHaveBeenCalledWith(Link.name);
        expect(commands.focus).toHaveBeenCalled();
        expect(commands.run).toHaveBeenCalled();
      });
    });

    describe('given the user has selected text', () => {
      beforeEach(() => {
        hasSelection.mockReturnValueOnce(true);
      });

      it('the editor does not modify the current selection', () => {
        buildWrapper();

        findDropdown().vm.$emit('show');
        expect(commands.extendMarkRange).not.toHaveBeenCalled();
        expect(commands.focus).not.toHaveBeenCalled();
        expect(commands.run).not.toHaveBeenCalled();
      });
    });
  });
});
