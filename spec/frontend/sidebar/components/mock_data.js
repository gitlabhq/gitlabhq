import { s__ } from '~/locale';

export const getIssueCrmContactsQueryResponse = {
  data: {
    issue: {
      __typename: 'Issue',
      id: 'gid://gitlab/Issue/123',
      customerRelationsContacts: {
        nodes: [
          {
            id: 'gid://gitlab/CustomerRelations::Contact/1',
            firstName: 'Someone',
            lastName: 'Important',
            email: 'si@gitlab.com',
            phone: null,
            description: null,
            organization: null,
          },
          {
            id: 'gid://gitlab/CustomerRelations::Contact/5',
            firstName: 'Marty',
            lastName: 'McFly',
            email: null,
            phone: null,
            description: null,
            organization: null,
          },
        ],
      },
    },
  },
};

export const getIssueCrmContactsQueryResponseEmpty = {
  data: {
    issue: {
      __typename: 'Issue',
      id: 'gid://gitlab/Issue/123',
      customerRelationsContacts: {
        nodes: [],
      },
    },
  },
};

export const issueCrmContactsUpdateNullResponse = {
  data: {
    issueCrmContactsUpdated: null,
  },
};

export const issueCrmContactsUpdateResponse = {
  data: {
    issueCrmContactsUpdated: {
      __typename: 'Issue',
      id: 'gid://gitlab/Issue/123',
      customerRelationsContacts: {
        nodes: [
          {
            id: 'gid://gitlab/CustomerRelations::Contact/13',
            firstName: 'Dave',
            lastName: 'Davies',
            email: 'dd@gitlab.com',
            phone: '+44 20 1111 2222',
            description: 'Vice President',
            organization: null,
          },
        ],
      },
    },
  },
};

export const mockSuggestedColors = {
  '#009966': s__('SuggestedColors|Green-cyan'),
  '#8fbc8f': s__('SuggestedColors|Dark sea green'),
  '#3cb371': s__('SuggestedColors|Medium sea green'),
  '#00b140': s__('SuggestedColors|Green screen'),
  '#013220': s__('SuggestedColors|Dark green'),
  '#6699cc': s__('SuggestedColors|Blue-gray'),
  '#0000ff': s__('SuggestedColors|Blue'),
  '#e6e6fa': s__('SuggestedColors|Lavender'),
  '#9400d3': s__('SuggestedColors|Dark violet'),
  '#330066': s__('SuggestedColors|Deep violet'),
  '#808080': s__('SuggestedColors|Gray'),
  '#36454f': s__('SuggestedColors|Charcoal grey'),
  '#f7e7ce': s__('SuggestedColors|Champagne'),
  '#c21e56': s__('SuggestedColors|Rose red'),
  '#cc338b': s__('SuggestedColors|Magenta-pink'),
  '#dc143c': s__('SuggestedColors|Crimson'),
  '#ff0000': s__('SuggestedColors|Red'),
  '#cd5b45': s__('SuggestedColors|Dark coral'),
  '#eee600': s__('SuggestedColors|Titanium yellow'),
  '#ed9121': s__('SuggestedColors|Carrot orange'),
  '#c39953': s__('SuggestedColors|Aztec Gold'),
};

export const mockSuggestedEpicColors = [
  { '#E9BE74': s__('WorkItem|Apricot') },
  { '#D99530': s__('WorkItem|Copper') },
  { '#C17D10': s__('WorkItem|Rust') },
  { '#F57F6C': s__('WorkItem|Pink') },
  { '#EC5941': s__('WorkItem|Vermilion') },
  { '#DD2B0E': s__('WorkItem|Red') },
  { '#C91C00': s__('WorkItem|Dark red') },
  { '#52B87A': s__('WorkItem|Teal') },
  { '#2DA160': s__('WorkItem|Green') },
  { '#108548': s__('WorkItem|Forest green') },
  { '#63A6E9': s__('WorkItem|Sky blue') },
  { '#428FDC': s__('WorkItem|Royal blue') },
  { '#1F75CB': s__('WorkItem|Blue') },
  { '#1068BF': s__('WorkItem|Midnight blue') },
];
