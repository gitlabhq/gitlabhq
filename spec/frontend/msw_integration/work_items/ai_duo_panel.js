const catalogAgentA = {
  id: 'gid://gitlab/Ai::Catalog::ConfiguredItem/1',
  pinnedVersionPrefix: '1',
  pinnedItemVersion: {
    id: 'gid://gitlab/Ai::Catalog::ItemVersion/10',
    __typename: 'AiCatalogItemVersion',
  },
  item: {
    id: 'gid://gitlab/Ai::Catalog::Item/1',
    name: 'Security Agent',
    description: 'Reviews code for security issues',
    __typename: 'AiCatalogItem',
  },
  __typename: 'AiCatalogConfiguredItem',
};

const catalogAgentB = {
  id: 'gid://gitlab/Ai::Catalog::ConfiguredItem/2',
  pinnedVersionPrefix: '1',
  pinnedItemVersion: {
    id: 'gid://gitlab/Ai::Catalog::ItemVersion/20',
    __typename: 'AiCatalogItemVersion',
  },
  item: {
    id: 'gid://gitlab/Ai::Catalog::Item/2',
    name: 'Planning Agent',
    description: 'Plans engineering work',
    __typename: 'AiCatalogItem',
  },
  __typename: 'AiCatalogConfiguredItem',
};

const foundationalAgentA = {
  id: 'gid://gitlab/Ai::Catalog::ItemVersion/100',
  name: 'Default Chat Agent',
  description: 'GitLab Duo default chat',
  referenceWithVersion: 'default_chat_agent@1',
  avatarUrl: null,
  selectableInChat: true,
  __typename: 'AiFoundationalChatAgent',
};

const threadOne = {
  id: 'gid://gitlab/Ai::Conversation::Thread/1',
  lastUpdatedAt: '2026-04-19T12:00:00Z',
  createdAt: '2026-04-19T10:00:00Z',
  conversationType: 'DUO_CHAT',
  title: 'Previous conversation about refactoring',
  __typename: 'AiConversationsThread',
};

const threadTwo = {
  id: 'gid://gitlab/Ai::Conversation::Thread/2',
  lastUpdatedAt: '2026-04-18T09:00:00Z',
  createdAt: '2026-04-18T08:00:00Z',
  conversationType: 'DUO_CHAT',
  title: 'Earlier conversation',
  __typename: 'AiConversationsThread',
};

const messageOne = {
  id: 'gid://gitlab/Ai::Message/1',
  requestId: 'req-thread-1-msg-1',
  content: 'How do I refactor this function?',
  contentHtml: '<p>How do I refactor this function?</p>',
  errors: [],
  role: 'USER',
  timestamp: '2026-04-19T10:00:00Z',
  extras: { sources: [], hasFeedback: false, __typename: 'AiMessageExtras' },
  __typename: 'AiMessage',
};

const messageTwo = {
  id: 'gid://gitlab/Ai::Message/2',
  requestId: 'req-thread-1-msg-2',
  content: 'You can extract the inner loop into a helper.',
  contentHtml: '<p>You can extract the inner loop into a helper.</p>',
  errors: [],
  role: 'ASSISTANT',
  timestamp: '2026-04-19T10:00:02Z',
  extras: { sources: [], hasFeedback: false, __typename: 'AiMessageExtras' },
  __typename: 'AiMessage',
};

export const fixtures = {
  threads: [threadOne, threadTwo],
  messagesForFirstThread: [messageOne, messageTwo],
  catalogAgents: [catalogAgentA, catalogAgentB],
  foundationalAgents: [foundationalAgentA],
};

const emptyPageInfo = {
  hasNextPage: false,
  endCursor: null,
  __typename: 'PageInfo',
};

const OPERATION_HANDLERS = {
  duoChatAvailable: () => ({
    data: {
      currentUser: {
        id: 'gid://gitlab/User/16',
        duoChatAvailable: true,
        __typename: 'CurrentUser',
      },
    },
  }),

  getAiConversationThreads: () => ({
    data: {
      aiConversationThreads: {
        nodes: fixtures.threads,
        pageInfo: { ...emptyPageInfo },
        __typename: 'AiConversationsThreadConnection',
      },
    },
  }),

  getAiMessagesWithThread: ({ variables }) => {
    const isFirstThread = variables?.threadId === threadOne.id;
    return {
      data: {
        aiMessages: {
          nodes: isFirstThread ? fixtures.messagesForFirstThread : [],
          __typename: 'AiMessageTypeConnection',
        },
      },
    };
  },

  getConfiguredAgents: () => ({
    data: {
      aiCatalogConfiguredItems: {
        nodes: fixtures.catalogAgents,
        pageInfo: { ...emptyPageInfo },
        __typename: 'AiCatalogConfiguredItemConnection',
      },
    },
  }),

  getFoundationalChatAgents: () => ({
    data: {
      aiFoundationalChatAgents: {
        nodes: fixtures.foundationalAgents,
        __typename: 'AiFoundationalChatAgentConnection',
      },
    },
  }),

  dismissUserCallout: ({ variables }) => ({
    data: {
      userCalloutCreate: {
        errors: [],
        userCallout: {
          dismissedAt: '2026-04-20T00:00:00Z',
          featureName: variables?.input?.featureName ?? 'duo_panel_auto_expanded',
          __typename: 'UserCallout',
        },
        __typename: 'UserCalloutCreatePayload',
      },
    },
  }),

  chat: ({ variables }) => ({
    data: {
      aiAction: {
        requestId: variables?.clientSubscriptionId ?? 'req-new-1',
        errors: [],
        threadId: variables?.threadId ?? null,
        __typename: 'AiActionPayload',
      },
    },
  }),

  deleteConversationThread: () => ({
    data: {
      deleteConversationThread: {
        errors: [],
        success: true,
        __typename: 'DeleteConversationThreadPayload',
      },
    },
  }),
};

export function handleAiDuoPanelOperation({ operationName, variables, res, ctx }) {
  const handler = OPERATION_HANDLERS[operationName];

  if (!handler) {
    return null;
  }

  const payload = handler({ operationName, variables });

  return res(ctx.json(payload));
}
