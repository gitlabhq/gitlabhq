import { observable } from '~/lib/utils/observable';
import { CHAT_MODES } from './constants';

export const portalState = observable('super_sidebar_portal_state', {
  ready: false,
});

export const sidebarState = observable('super_sidebar_state', {
  isCollapsed: false,
  isMobile: false,
  isIconOnly: false,
  hasPeeked: false,
  isPeek: false,
  isPeekable: false,
  isHoverPeek: false,
  wasHoverPeek: false,
});

export const duoChatGlobalState = observable('duo_chat_global_state', {
  commands: [],
  isShown: false,
  isAgenticChatShown: false,
  chatMode: CHAT_MODES.CLASSIC, // CHAT_MODES.CLASSIC or CHAT_MODES.AGENTIC - single source of truth for chat mode
  focusChatInput: false, // Set to true to force the chat input to focus when the chat is expanded
  lastRoutePerTab: {}, // Tracks the last visited route for each tab (e.g., { sessions: '/agent-sessions/123' })
  activeThread: undefined, // Persisted across component recreations when overlay closes/reopens
  multithreadedView: 'chat', // Persisted view state: 'chat' or 'list'
});
