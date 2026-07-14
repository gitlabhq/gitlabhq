import { observable } from '~/lib/utils/observable';
import { CHAT_MODES } from './constants';

export const portalState = observable('super_sidebar_portal_state', {
  ready: false,
});

export const sidebarState = observable('super_sidebar_state', {
  isCollapsed: false,
  isMobile: false,
  isIconOnly: false,
});

export const duoChatGlobalState = observable('duo_chat_global_state', {
  commands: [],
  chatMode: CHAT_MODES.CLASSIC, // CHAT_MODES.CLASSIC or CHAT_MODES.AGENTIC - single source of truth for chat mode
  focusChatInput: false, // Set to true to force the chat input to focus when the chat is expanded
  lastRoutePerTab: {}, // Tracks the last visited route for each tab (e.g., { sessions: '/agent-sessions/123' })
  activeThread: undefined, // Persisted across component recreations when overlay closes/reopens
  multithreadedView: 'chat', // Persisted view state: 'chat' or 'list'
  aiPanelDragWidth: null, // number (px) when user has dragged; null = use CSS clamp default. Session-only.
});
