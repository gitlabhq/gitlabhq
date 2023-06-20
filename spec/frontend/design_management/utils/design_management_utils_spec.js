import {
  extractCurrentDiscussion,
  extractDiscussions,
  findVersionId,
  designUploadOptimisticResponse,
  repositionImageDiffNoteOptimisticResponse,
  isValidDesignFile,
  extractDesign,
  extractDesignNoteId,
} from '~/design_management/utils/design_management_utils';
import mockDesign from '../mock_data/design';
import mockResponseWithDesigns from '../mock_data/designs';
import mockResponseNoDesigns from '../mock_data/no_designs';

jest.mock('lodash/uniqueId', () => () => 1);

describe('extractCurrentDiscussion', () => {
  let discussions;

  beforeEach(() => {
    discussions = {
      nodes: [
        { id: 101, payload: 'w' },
        { id: 102, payload: 'x' },
        { id: 103, payload: 'y' },
        { id: 104, payload: 'z' },
      ],
    };
  });

  it('finds the relevant discussion if it exists', () => {
    const id = 103;
    expect(extractCurrentDiscussion(discussions, id)).toEqual({ id, payload: 'y' });
  });

  it('returns null if the relevant discussion does not exist', () => {
    expect(extractCurrentDiscussion(discussions, 0)).not.toBeDefined();
  });
});

describe('extractDiscussions', () => {
  let discussions;

  beforeEach(() => {
    discussions = {
      nodes: [
        { id: 1, notes: { nodes: ['a'] } },
        { id: 2, notes: { nodes: ['b'] } },
        { id: 3, notes: { nodes: ['c'] } },
        { id: 4, notes: { nodes: ['d'] } },
      ],
    };
  });

  it('discards the node artifacts of GraphQL', () => {
    expect(extractDiscussions(discussions)).toEqual([
      { id: 1, notes: ['a'], index: 1 },
      { id: 2, notes: ['b'], index: 2 },
      { id: 3, notes: ['c'], index: 3 },
      { id: 4, notes: ['d'], index: 4 },
    ]);
  });
});

describe('version parser', () => {
  it('correctly extracts version ID from a valid version string', () => {
    const testVersionId = '123';
    const testVersionString = `gid://gitlab/DesignManagement::Version/${testVersionId}`;

    expect(findVersionId(testVersionString)).toEqual(testVersionId);
  });

  it('fails to extract version ID from an invalid version string', () => {
    const testInvalidVersionString = `gid://gitlab/DesignManagement::Version`;

    expect(findVersionId(testInvalidVersionString)).toBeUndefined();
  });
});

describe('optimistic responses', () => {
  it('correctly generated for designManagementUpload', () => {
    const expectedResponse = {
      __typename: 'Mutation',
      designManagementUpload: {
        __typename: 'DesignManagementUploadPayload',
        designs: [
          {
            __typename: 'Design',
            id: -1,
            image: '',
            imageV432x230: '',
            description: '',
            descriptionHtml: '',
            filename: 'test',
            fullPath: '',
            notesCount: 0,
            event: 'NONE',
            currentUserTodos: {
              __typename: 'TodoConnection',
              nodes: [],
            },
            diffRefs: { __typename: 'DiffRefs', baseSha: '', startSha: '', headSha: '' },
            discussions: { __typename: 'DesignDiscussion', nodes: [] },
            versions: {
              __typename: 'DesignVersionConnection',
              nodes: {
                __typename: 'DesignVersion',
                id: expect.anything(),
                sha: expect.anything(),
                createdAt: '',
                author: { __typename: 'UserCore', avatarUrl: '', name: '', id: expect.anything() },
              },
            },
          },
        ],
        errors: [],
        skippedDesigns: [],
      },
    };
    expect(designUploadOptimisticResponse([{ name: 'test' }])).toEqual(expectedResponse);
  });

  it('correctly generated for repositionImageDiffNoteOptimisticResponse', () => {
    const mockNote = {
      id: 'test-note-id',
    };

    const mockPosition = {
      x: 10,
      y: 10,
      width: 10,
      height: 10,
    };

    const expectedResponse = {
      __typename: 'Mutation',
      repositionImageDiffNote: {
        __typename: 'RepositionImageDiffNotePayload',
        note: {
          ...mockNote,
          position: mockPosition,
        },
        errors: [],
      },
    };
    expect(repositionImageDiffNoteOptimisticResponse(mockNote, { position: mockPosition })).toEqual(
      expectedResponse,
    );
  });
});

describe('isValidDesignFile', () => {
  // test every filetype that Design Management supports
  // https://docs.gitlab.com/ee/user/project/issues/design_management.html#limitations
  it.each`
    mimetype                      | isValid
    ${'image/svg'}                | ${true}
    ${'image/png'}                | ${true}
    ${'image/jpg'}                | ${true}
    ${'image/jpeg'}               | ${true}
    ${'image/gif'}                | ${true}
    ${'image/bmp'}                | ${true}
    ${'image/tiff'}               | ${true}
    ${'image/ico'}                | ${true}
    ${'image/svg'}                | ${true}
    ${'video/mpeg'}               | ${false}
    ${'audio/midi'}               | ${false}
    ${'application/octet-stream'} | ${false}
  `('returns $isValid for file type $mimetype', ({ mimetype, isValid }) => {
    expect(isValidDesignFile({ type: mimetype })).toBe(isValid);
  });
});

describe('extractDesign', () => {
  describe('with no designs', () => {
    it('returns undefined', () => {
      expect(extractDesign(mockResponseNoDesigns)).toBeUndefined();
    });
  });

  describe('with designs', () => {
    it('returns the first design available', () => {
      expect(extractDesign(mockResponseWithDesigns)).toEqual(mockDesign);
    });
  });
});

describe('extractDesignNoteId', () => {
  it.each`
    hash            | expectedNoteId
    ${'#note_0'}    | ${'0'}
    ${'#note_1'}    | ${'1'}
    ${'#note_23'}   | ${'23'}
    ${'#note_456'}  | ${'456'}
    ${'note_1'}     | ${null}
    ${'#note_'}     | ${null}
    ${'#note_asd'}  | ${null}
    ${'#note_1asd'} | ${null}
  `('returns $expectedNoteId when hash is $hash', ({ hash, expectedNoteId }) => {
    expect(extractDesignNoteId(hash)).toBe(expectedNoteId);
  });
});
