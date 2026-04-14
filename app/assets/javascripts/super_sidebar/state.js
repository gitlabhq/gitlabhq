import Vue from 'vue';
import { CHAT_MODES } from './constants';

export const portalState = Vue.observable({
  ready: false,
});

export const sidebarState = Vue.observable({
  isCollapsed: false,
  isMobile: false,
  isIconOnly: false,
  hasPeeked: false,
  isPeek: false,
  isPeekable: false,
  isHoverPeek: false,
  wasHoverPeek: false,
});

export const duoChatGlobalState = Vue.observable({
  commands: [],
  isShown: false,
  isAgenticChatShown: false,
  chatMode: CHAT_MODES.CLASSIC, // CHAT_MODES.CLASSIC or CHAT_MODES.AGENTIC - single source of truth for chat mode
  activeTab: null, // For embedded mode: which tab is active in the AI panel ('chat', 'history', etc.)
  focusChatInput: false, // // Set to true to force the chat input to focus when the chat is expanded
  lastRoutePerTab: {}, // Tracks the last visited route for each tab (e.g., { sessions: '/agent-sessions/123' })
  activeThread: undefined, // Persisted across component recreations when overlay closes/reopens
  multithreadedView: 'chat', // Persisted view state: 'chat' or 'list'
});
