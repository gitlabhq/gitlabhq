import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import { Mousetrap } from '~/lib/mousetrap';
import {
  ISSUABLE_CHANGE_LABEL,
  ISSUABLE_COPY_REF,
  ISSUABLE_EDIT_DESCRIPTION,
  ISSUE_MR_CHANGE_ASSIGNEE,
  ISSUE_MR_CHANGE_MILESTONE,
  MR_COPY_SOURCE_BRANCH_NAME,
} from '~/behaviors/shortcuts/keybindings';
import Sidebar from '~/right_sidebar';

jest.mock('~/right_sidebar');
jest.mock('clipboard');

describe('ShortcutsIssuable', () => {
  const init = () => {
    const addAll = (shortcuts) => {
      shortcuts.forEach(([config, callback]) => {
        Mousetrap.bind(config.defaultKeys[0], callback);
      });
    };
    return new ShortcutsIssuable({ addAll });
  };

  beforeEach(() => {
    resetHTMLFixture();
    Mousetrap.reset();
  });

  describe('sidebars', () => {
    it.each`
      shortcut                     | sidebarName
      ${ISSUE_MR_CHANGE_ASSIGNEE}  | ${'assignee'}
      ${ISSUE_MR_CHANGE_MILESTONE} | ${'milestone'}
      ${ISSUABLE_CHANGE_LABEL}     | ${'labels'}
    `('opens $sidebarName sidebar on $shortcut.description hotkey', ({ shortcut, sidebarName }) => {
      setHTMLFixture(
        `<div class="block ${sidebarName}"><button class="shortcut-sidebar-dropdown-toggle"></button></div>`,
      );
      const clickSpy = jest.spyOn(
        document.querySelector(`.block.${sidebarName} .shortcut-sidebar-dropdown-toggle`),
        'click',
      );
      Sidebar.instance = new Sidebar();
      init();

      Mousetrap.trigger(shortcut.defaultKeys[0]);

      expect(Sidebar.instance.openDropdown).toHaveBeenCalledWith(sidebarName);
      jest.runAllTimers();
      expect(clickSpy).toHaveBeenCalled();
    });
  });

  it('clicks edit issue', () => {
    setHTMLFixture('<button class="js-issuable-edit"></button>');
    const clickSpy = jest.spyOn(document.querySelector('.js-issuable-edit'), 'click');
    init();
    Mousetrap.trigger(ISSUABLE_EDIT_DESCRIPTION.defaultKeys[0]);
    expect(clickSpy).toHaveBeenCalled();
  });

  describe('copy', () => {
    it.each`
      shortcut                      | buttonClass                | buttonInstanceName
      ${MR_COPY_SOURCE_BRANCH_NAME} | ${'js-source-branch-copy'} | ${'branchInMemoryButton'}
      ${ISSUABLE_COPY_REF}          | ${'js-copy-reference'}     | ${'refInMemoryButton'}
    `('performs $shortcut.description', ({ shortcut, buttonClass, buttonInstanceName }) => {
      setHTMLFixture(`<button class="${buttonClass}" data-clipboard-text="foo"></button>`);
      const instance = init();
      const clickSpy = jest.fn();
      instance[buttonInstanceName].addEventListener('click', clickSpy);
      Mousetrap.trigger(shortcut.defaultKeys[0]);
      expect(instance[buttonInstanceName].dataset.clipboardText).toBe('foo');
      expect(clickSpy).toHaveBeenCalled();
    });
  });
});
