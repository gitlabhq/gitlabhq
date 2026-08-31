export const WORK_ITEM_ID = 'gid://gitlab/WorkItem/1';

export const workItemFeaturesData = ({ widget, typename, value }) => ({
  workItem: {
    __typename: 'WorkItem',
    id: WORK_ITEM_ID,
    features: {
      __typename: 'WorkItemFeatures',
      [widget]: value === null ? null : { __typename: typename, ...value },
    },
  },
});

// Each widget is written by two documents: one carrying the data and one carrying only a
// cheap field, which is how a detail query and a dedicated query end up sharing a wrapper.
export const workItemFeaturesMergeScenarios = [
  {
    widget: 'crmContacts',
    typename: 'WorkItemWidgetCrmContacts',
    dataSelection: 'contacts { __typename nodes { __typename id } }',
    dataValue: {
      contacts: {
        __typename: 'CustomerRelationsContactConnection',
        nodes: [{ __typename: 'CustomerRelationsContact', id: 'gid://gitlab/Contact/1' }],
      },
    },
    partialSelection: 'contactsAvailable',
    partialValue: { contactsAvailable: true },
  },
  {
    widget: 'hierarchy',
    typename: 'WorkItemWidgetHierarchy',
    dataSelection: 'hasChildren',
    dataValue: { hasChildren: true },
    partialSelection: 'parent { __typename id }',
    partialValue: { parent: { __typename: 'WorkItem', id: 'gid://gitlab/WorkItem/2' } },
  },
  {
    widget: 'awardEmoji',
    typename: 'WorkItemWidgetAwardEmoji',
    dataSelection: 'awardEmoji { __typename nodes { __typename id } }',
    dataValue: {
      awardEmoji: {
        __typename: 'AwardEmojiConnection',
        nodes: [{ __typename: 'AwardEmoji', id: 'gid://gitlab/AwardEmoji/1' }],
      },
    },
    partialSelection: 'upvotes',
    partialValue: { upvotes: 3 },
  },
  {
    widget: 'notes',
    typename: 'WorkItemWidgetNotes',
    dataSelection: 'discussions { __typename nodes { __typename id } }',
    dataValue: {
      discussions: {
        __typename: 'DiscussionConnection',
        nodes: [{ __typename: 'Discussion', id: 'gid://gitlab/Discussion/1' }],
      },
    },
    partialSelection: 'discussionLocked',
    partialValue: { discussionLocked: true },
  },
];
