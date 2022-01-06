export const getGroupContactsQueryResponse = {
  data: {
    group: {
      __typename: 'Group',
      id: 'gid://gitlab/Group/26',
      contacts: {
        nodes: [
          {
            __typename: 'CustomerRelationsContact',
            id: 'gid://gitlab/CustomerRelations::Contact/12',
            firstName: 'Marty',
            lastName: 'McFly',
            email: 'example@gitlab.com',
            phone: null,
            description: null,
            organization: {
              __typename: 'CustomerRelationsOrganization',
              id: 'gid://gitlab/CustomerRelations::Organization/2',
              name: 'Tech Giant Inc',
            },
          },
          {
            __typename: 'CustomerRelationsContact',
            id: 'gid://gitlab/CustomerRelations::Contact/16',
            firstName: 'Boy',
            lastName: 'George',
            email: null,
            phone: null,
            description: null,
            organization: null,
          },
          {
            __typename: 'CustomerRelationsContact',
            id: 'gid://gitlab/CustomerRelations::Contact/13',
            firstName: 'Jane',
            lastName: 'Doe',
            email: 'jd@gitlab.com',
            phone: '+44 44 4444 4444',
            description: 'Vice President',
            organization: null,
          },
        ],
      },
    },
  },
};

export const getGroupOrganizationsQueryResponse = {
  data: {
    group: {
      __typename: 'Group',
      id: 'gid://gitlab/Group/26',
      organizations: {
        nodes: [
          {
            __typename: 'CustomerRelationsOrganization',
            id: 'gid://gitlab/CustomerRelations::Organization/1',
            name: 'Test Inc',
            defaultRate: 100,
            description: null,
          },
          {
            __typename: 'CustomerRelationsOrganization',
            id: 'gid://gitlab/CustomerRelations::Organization/2',
            name: 'ABC Company',
            defaultRate: 110,
            description: 'VIP',
          },
          {
            __typename: 'CustomerRelationsOrganization',
            id: 'gid://gitlab/CustomerRelations::Organization/3',
            name: 'GitLab',
            defaultRate: 120,
            description: null,
          },
        ],
      },
    },
  },
};

export const createContactMutationResponse = {
  data: {
    customerRelationsContactCreate: {
      contact: {
        __typename: 'CustomerRelationsContact',
        id: 'gid://gitlab/CustomerRelations::Contact/1',
        firstName: 'A',
        lastName: 'B',
        email: 'C',
        phone: null,
        description: null,
        organization: null,
      },
      errors: [],
    },
  },
};

export const createContactMutationErrorResponse = {
  data: {
    customerRelationsContactCreate: {
      contact: null,
      errors: ['create contact is invalid.'],
    },
  },
};

export const updateContactMutationResponse = {
  data: {
    customerRelationsContactUpdate: {
      __typeName: 'CustomerRelationsContactCreatePayload',
      contact: {
        __typename: 'CustomerRelationsContact',
        id: 'gid://gitlab/CustomerRelations::Contact/1',
        firstName: 'First',
        lastName: 'Last',
        email: 'email@example.com',
        phone: null,
        description: null,
        organization: null,
      },
      errors: [],
    },
  },
};

export const updateContactMutationErrorResponse = {
  data: {
    customerRelationsContactUpdate: {
      contact: null,
      errors: ['update contact is invalid.'],
    },
  },
};

export const createOrganizationMutationResponse = {
  data: {
    customerRelationsOrganizationCreate: {
      organization: {
        __typename: 'CustomerRelationsOrganization',
        id: 'gid://gitlab/CustomerRelations::Organization/2',
        name: 'A',
        defaultRate: null,
        description: null,
      },
      errors: [],
    },
  },
};

export const createOrganizationMutationErrorResponse = {
  data: {
    customerRelationsOrganizationCreate: {
      organization: null,
      errors: ['create organization is invalid.'],
    },
  },
};
