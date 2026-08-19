// Lives in its own file (rather than shortcuts.js) so that ~/lib/mousetrap can
// import it without creating a circular dependency: shortcuts.js imports
// Mousetrap from ~/lib/mousetrap.
export const keyboardShortcutsDisabled = () => !window.gon.keyboard_shortcuts_enabled;
