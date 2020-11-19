export const designListQueryResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: '1',
      issue: {
        __typename: 'Issue',
        designCollection: {
          __typename: 'DesignCollection',
          copyState: 'READY',
          designs: {
            __typename: 'DesignConnection',
            nodes: [
              {
                __typename: 'Design',
                id: '1',
                event: 'NONE',
                filename: 'fox_1.jpg',
                notesCount: 3,
                image: 'image-1',
                imageV432x230: 'image-1',
                currentUserTodos: {
                  __typename: 'ToDo',
                  nodes: [],
                },
              },
              {
                __typename: 'Design',
                id: '2',
                event: 'NONE',
                filename: 'fox_2.jpg',
                notesCount: 2,
                image: 'image-2',
                imageV432x230: 'image-2',
                currentUserTodos: {
                  __typename: 'ToDo',
                  nodes: [],
                },
              },
              {
                __typename: 'Design',
                id: '3',
                event: 'NONE',
                filename: 'fox_3.jpg',
                notesCount: 1,
                image: 'image-3',
                imageV432x230: 'image-3',
                currentUserTodos: {
                  __typename: 'ToDo',
                  nodes: [],
                },
              },
            ],
          },
          versions: {
            __typename: 'DesignVersion',
            nodes: [],
          },
        },
      },
    },
  },
};

export const designUploadMutationCreatedResponse = {
  data: {
    designManagementUpload: {
      designs: [
        {
          id: '1',
          event: 'CREATION',
          filename: 'fox_1.jpg',
        },
      ],
    },
  },
};

export const designUploadMutationUpdatedResponse = {
  data: {
    designManagementUpload: {
      designs: [
        {
          id: '1',
          event: 'MODIFICATION',
          filename: 'fox_1.jpg',
        },
      ],
    },
  },
};

export const permissionsQueryResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: '1',
      issue: {
        __typename: 'Issue',
        userPermissions: { __typename: 'UserPermissions', createDesign: true },
      },
    },
  },
};

export const reorderedDesigns = [
  {
    __typename: 'Design',
    id: '2',
    event: 'NONE',
    filename: 'fox_2.jpg',
    notesCount: 2,
    image: 'image-2',
    imageV432x230: 'image-2',
    currentUserTodos: {
      __typename: 'ToDo',
      nodes: [],
    },
  },
  {
    __typename: 'Design',
    id: '1',
    event: 'NONE',
    filename: 'fox_1.jpg',
    notesCount: 3,
    image: 'image-1',
    imageV432x230: 'image-1',
    currentUserTodos: {
      __typename: 'ToDo',
      nodes: [],
    },
  },
  {
    __typename: 'Design',
    id: '3',
    event: 'NONE',
    filename: 'fox_3.jpg',
    notesCount: 1,
    image: 'image-3',
    imageV432x230: 'image-3',
    currentUserTodos: {
      __typename: 'ToDo',
      nodes: [],
    },
  },
];

export const moveDesignMutationResponse = {
  data: {
    designManagementMove: {
      designCollection: {
        __typename: 'DesignCollection',
        designs: {
          __typename: 'DesignConnection',
          nodes: [...reorderedDesigns],
        },
      },
      errors: [],
    },
  },
};

export const moveDesignMutationResponseWithErrors = {
  data: {
    designManagementMove: {
      designCollection: {
        designs: {
          nodes: [...reorderedDesigns],
        },
      },
      errors: ['Houston, we have a problem'],
    },
  },
};
