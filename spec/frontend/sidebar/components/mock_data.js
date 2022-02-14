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
