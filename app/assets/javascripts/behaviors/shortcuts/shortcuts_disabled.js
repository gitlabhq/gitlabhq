// Lives in its own file (rather than shortcuts_toggle.js) so that
// ~/lib/mousetrap can import it without creating a circular dependency:
// shortcuts_toggle.js imports Mousetrap from ~/lib/mousetrap.
export const shouldDisableShortcuts = () => !window.gon.keyboard_shortcuts_enabled;
